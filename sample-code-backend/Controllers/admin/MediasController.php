<?php
/**
 * Medias Controller
 *
 * @category MediasController
 * @package  Controller
 */

namespace App\Http\Controllers;

use Illuminate\Http\Request;

use App\Http\Requests;
use Config;
use App\Role;
use App\User;
use App\Media;
use Mail;
use App\Libraries\amazonS3;

class MediasController extends Controller
{
    /**
     * Media listing page.
     *
     * @return \Illuminate\Http\Response
     */
    public function index()
    {
        
        $medias = [];
        return view('admin.medias.index', compact('medias'));
    }

    /**
     * Media ajax function for listing in datatable.
     *
     * @param \Illuminate\Http\Request $request All Request Parameters.
     *
     * @return \Illuminate\Http\Response
     */
    public function page(Request $request)
    {
        
        $columns = array( 
                            0 =>'id', 
                            1 =>'name',
                            2=> 'uploaded_by',
                            3=> 'email',
                            4=> 'created_at',
                            5=> 'id',
                        );
  
        $totalData = Media::count();
            
        $totalFiltered = $totalData; 

        $limit = $request->input('length');
        $start = $request->input('start');
        $order = $columns[$request->input('order.0.column')];
        $dir = $request->input('order.0.dir');
            
        if (empty($request->input('search.value'))) {            
            $medias = Media::offset($start)
                         ->limit($limit)
                         ->orderBy($order, $dir)
                         ->get();
        } else {
            $search = $request->input('search.value'); 

            $medias =  Media::where('id', 'LIKE', "%{$search}%")
                            ->orWhere('uploaded_by', 'LIKE', "%{$search}%")
                            ->orWhere('name', 'LIKE', "%{$search}%")
                            ->orWhere('email', 'LIKE', "%{$search}%")
                            ->orWhere('type', 'LIKE', "%{$search}%")
                            ->offset($start)
                            ->limit($limit)
                            ->orderBy($order, $dir)
                            ->get();

            $totalFiltered = Media::where('id', 'LIKE', "%{$search}%")
                             ->orWhere('uploaded_by', 'LIKE', "%{$search}%")
                             ->orWhere('name', 'LIKE', "%{$search}%")
                             ->orWhere('email', 'LIKE', "%{$search}%")
                             ->orWhere('type', 'LIKE', "%{$search}%")
                             ->count();
        }

        $data = array();
        if (!empty($medias)) {
            foreach ($medias as $media) {
                $publish =  route('medias.change-status', $media->id);
                $export =  route('medias.export', $media->id);
                $destroy =  route('medias.delete', $media->id);
                $csrf_token = csrf_token();
                $publish_text = ($media->status > 0) ? 'Unpublish':'Publish';

                $nestedData['DT_RowId'] = 'row_'.$media->id;
                $nestedData['id'] = $media->id;
                $nestedData['name'] = $media->name;
                $nestedData['uploaded_by'] = $media->uploaded_by;
                $nestedData['email'] = $media->email;
                $nestedData['created_at'] = date('Y-m-d h:i A', strtotime($media->created_at));
                $nestedData['type'] = ucfirst($media->type);
                $nestedData['status'] = '<a href="javascript:void(0);" class="btn btn-xs btn-info change-status">'.$publish_text.'</a>';
                $nestedData['actions'] = '<a href="'.$export.'" class="btn btn-xs btn-success" title="Export"><i class="fa fa-download" aria-hidden="true"></i></a>
                                          <a href="#" class="btn btn-xs btn-primary play-video" data-url="'.$media->url.'" title="Play"><i class="fa fa-play" aria-hidden="true"></i></a>
                                          <a href="javascript:void(0);" class="btn btn-xs btn-danger delete-media" title="Delete"><i class="fa fa-trash-o" aria-hidden="true"></i></a>';
                $data[] = $nestedData;

            }
        }
          
        $json_data = array(
                    "draw"            => intval($request->input('draw')),  
                    "recordsTotal"    => intval($totalData),  
                    "recordsFiltered" => intval($totalFiltered), 
                    "data"            => $data   
                    );
            
        echo json_encode($json_data); 
    }

    /**
     * Change status to publish/unpublish.
     *
     * @param \Illuminate\Http\Request $request All Request Parameters.
     *
     * @return \Illuminate\Http\Response
     */
    public function changeStatus(Request $request)
    {
        $return_status = 0;
        $response = [];
        if ($request->has('id')) {
            $id = trim($request->input('id'));

            $media = Media::findOrFail($id);
            
            if ($media) {

                $media->status = ($media->status==1)?0:1;
                $result = $media->save();
                if ($result) {
                    //@todo - send an email to the person whenever their recording gets published.
                    if ($media->status==1) {
                        $email = $media->email;
                        $name = $media->uploaded_by;
                        $bodyMessage = '#'.$id.' Published';
                        $data = array('email'=>$email, 'name'=>$name, 'recording_code'=>$id,'bodyMessage'=>'','subject'=>'');

                        $user  = User::findOrFail(1);
                        $admin_email = $user->email;
                        $admin_name = $user->name;

                        if ($email) {
                            Mail::send(
								{
									'emails.publish_notify', $data, function ($message) use ($email, $admin_email, $admin_name) {
										$message->to($admin_email, $admin_name)->subject('Your Recording Has Been Published - '.config('app.name'));
								}
                            );
                        }
                    }
                    
                    $return_status = 1;
                    $response['is_published']  = $media->status;
                    $response['message']  = ($media->status==1)?trans('quickadmin::admin.medias-controller-successfully_published'):trans('quickadmin::admin.medias-controller-successfully_unpublished');
                }
            }
        }
        $response['status'] = $return_status;
        echo json_encode($response); 
    }

    /**
     * Download media from s3 bucket.
     *
     * @param int $id Media id.
     *
     * @return \Illuminate\Http\RedirectResponse
     */
    public function export($id)
    {
        
        //download video.
        $media = Media::findOrFail($id);
        
        if ($media) {

            $s3 = new amazonS3();
            $response = $s3->downloadFile($media->name);
            if (!$response) {
                return redirect()->route('medias.index')->withMessage(trans('quickadmin::admin.medias-controller-media_not_exists'));
            }            
        }

        return redirect()->route('medias.index');
    }

    /**
     * Delete media.
     *
     * @param \Illuminate\Http\Request $request All Request Parameters.
     *
     * @return \Illuminate\Http\Response
     */
    public function delete(Request $request)
    {
        $return_status = 0;
        $response = [];
        if ($request->has('id')) {
            $id = trim($request->input('id'));
            $media = Media::findOrFail($id);
            
            Media::destroy($id);
            $return_status = 1;
            $response['message']  = trans('quickadmin::admin.medias-controller-successfully_deleted');
        }
        $response['status'] = $return_status;
        echo json_encode($response); 
    }

    /**
     * Bulk actions - publish/unpublish/delete.
     *
     * @param \Illuminate\Http\Request $request All request parameters.
     *
     * @return \Illuminate\Http\Response
     */
    public function bulkUpdate(Request $request)
    {
        $message = 'No medias are selected!';
        if ($request->has('bulk-action')) {
            $action = $request->input('bulk-action');
            $media_ids = $request->input('media');
            switch ($action) {
            case 'publish':
                Media::whereIn('id', $media_ids)->update(array('status' => 1));
                $message= trans('quickadmin::admin.medias-controller-bulk_successfully_published');
                break;
            case 'unpublish':
                Media::whereIn('id', $media_ids)->update(array('status' => 0));
                $message= trans('quickadmin::admin.medias-controller-bulk_successfully_unpublished');
                break;
            case 'delete':
                Media::whereIn('id', $media_ids)->delete(); 
                $message= trans('quickadmin::admin.medias-controller-bulk_successfully_deleted');
                break;
            default:
                break;
            }
        }

        return redirect()->route('medias.index')->withMessage($message);
    }
}
