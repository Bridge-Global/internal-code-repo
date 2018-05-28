<?php
/**
 * Category Controller
 *
 * @category CategoryController
 * @package  Controller
 */

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Http\Requests;
use App\Category;
use App\Product;
use Tymon\JWTAuth\Facades\JWTAuth;
use Tymon\JWTAuth\Exceptions\JWTException;
use Response;


class CategoryController extends Controller
{
    /**
     * Constructor.
     */
    public function __construct() 
    {

        $this->middleware('jwt.auth', ['except' => ['get','categoryCount','listPopularCategories']]);
        $this->category = new Category;
    }

    /**
     * API for getting all product categories.
     *
     * @api {post} /api/categories/get_main Getting all product categories.
     * @apiDescription getting all product categories.
     *
     * @return \Illuminate\Http\Response
     */
    public function get() 
    {
        $categories = Category::all();
        $this->status = 'success';
        $done = array('status' => $this->status, 'categories' => $categories);

        return Response::json($done, 200);
    }

    /**
     * API for getting total products count of each category.
     *
     * @api {post} /api/categories/categoryCount Getting total product counts of categories.
     * @apiDescription getting total product counts of categories.
     *
     * @param \Illuminate\Http\Request $request All request parameters.
     *
     * @return \Illuminate\Http\Response
     */
    public function categoryCount(Request $request) 
    {
        $category = new Category;
        $data = $request->json()->all();
        $latitude = $data['latitude'];
        $longitude = $data['longitude'];
        $latAndLong = $this->getLatLongDetails($latitude, $longitude);
        
        $maxLat = $latAndLong['maxLat'];
        $minLat = $latAndLong['minLat'];
        $maxLon = $latAndLong['maxLon'];
        $minLon = $latAndLong['minLon'];


        $getDetails = $category->getAllCategoryDetails();
        
        $categoryInfo = array();
        $cCount = 0;
        foreach ($getDetails as  $val) {
            if ($cCount>5) break;
            $categoryDetails = array();
            $categoryDetails['category_name'] = $val->category_name;
            $categoryDetails['slug'] = $val->slug;
            $categoryDetails['icon'] = $val->icon;
            
            $pCount = 0;
            $getCountDetails = $category->getAllCategoryCount($val->id, $maxLat, $minLat, $maxLon, $minLon);
            foreach ($getCountDetails as  $val) {
                $pCount = $val->pcount;
            }    
            
            $categoryDetails['pcount'] = $pCount;
            $categoryInfo[] = $categoryDetails;
            $cCount++;
          
        }
        
        $this->status = 'success';
        $done = array('status' => $this->status, 'categories' => $categoryInfo);

        return Response::json($done, 200);
    }
    
    /**
     * Function for getting latitude and logintude information within radius.
     *
     * @param string $latitude  latitude.
     * @param string $longitude longitude.
     *
     * @return \Illuminate\Http\Response
     */
    public function getLatLongDetails($latitude,$longitude) 
    {
        
        $radius = env('ZIP_RADIUS', 25);
        $earthRadius = env('EARTH_MEAN_RADIUS', 6371);
        if (isset($latitude) && !empty($latitude) && isset($longitude) && !empty($longitude)) {
            $maxLat = $latitude + rad2deg($radius/$earthRadius);
            $minLat = $latitude - rad2deg($radius/$earthRadius);
            $maxLon = $longitude + rad2deg(asin($radius/$earthRadius) / cos(deg2rad($latitude)));
            $minLon = $longitude - rad2deg(asin($radius/$earthRadius) / cos(deg2rad($latitude)));
        } else {
            $maxLat = '';
            $minLat = '' ;
            $maxLon = '';
            $minLon = '';
        }
        $result['maxLat'] = $maxLat;
        $result['minLat'] = $minLat;
        $result['maxLon'] = $maxLon;
        $result['minLon'] = $minLon;
        return $result;
        
    }

    /**
     * API for getting popular categories.
     *
     * @api {post} /api/categories/listPopularCategories Getting popular categories.
     * @apiDescription getting popular categories.
     *
     * @param \Illuminate\Http\Request $request All request parameters.
     *
     * @return \Illuminate\Http\Response
     */
    public function listPopularCategories(Request $request)
    {
        $data = $request->json()->all();
        if ($data['logged']==1) {
            $this->logged_user = JWTAuth::parseToken()->authenticate();
            $id                = $this->logged_user->id;
        } else {
            $id=null;
        }

        $latitude = $data['latitude'];
        $longitude = $data['longitude'];
        $latAndLong = $this->getLatLongDetails($latitude, $longitude);
        
        $maxLat = $latAndLong['maxLat'];
        $minLat = $latAndLong['minLat'];
        $maxLon = $latAndLong['maxLon'];
        $minLon = $latAndLong['minLon'];

        //category listing of most popular products.
        $category         = new Category;
        $getDetails = $category->getAllCategoryDetails();
        
        $categoryInfo = array();
        foreach ($getDetails as  $val) {
            $categoryDetails = array();
            $categoryDetails['category_name'] = $val->category_name;
            $categoryDetails['slug'] = $val->slug;
            $categoryDetails['icon'] = $val->icon;
            
            $product         = new Product;
            $popular = $product->getPopularProducts($val->id, $maxLat, $minLat, $maxLon, $minLon);
            $categoryDetails['popularcount'] = intval($popular);//popular products count

            $pCount = 0;
            $getCountDetails = $category->getAllCategoryCount($val->id, $maxLat, $minLat, $maxLon, $minLon);
            foreach ($getCountDetails as  $val) {
                $pCount = $val->pcount;
            }    

            $categoryDetails['pcount'] = $pCount;
            $categoryInfo[] = $categoryDetails;
          
        }

        //sort by popular products count.
        usort(
            $categoryInfo, function ($a, $b) {
                //return $b['pcount'] - $a['pcount'];
                return $b['popularcount'] - $a['popularcount'];
            }
        );
        
        $this->status = 'success';
        $done = array('status' => $this->status, 'categories' => $categoryInfo);

        return Response::json($done, 200);
    }

    /**
     * API for getting all categories.
     * @api {post} /api/categories/getCategories getting all categories.
     * @apiDescription getting all categories.
     *
     * @param \Illuminate\Http\Request $request All request parameters.
     *
     * @return \Illuminate\Http\Response
     */
    public function getCategories(Request $request)
    {

         $data = $request->json()->all();
         
        if (isset($data['search'])) {
            $search_data= $data['search'];
        } else {
            $search_data= '';
 
        }
         
         $category = new Category;
        $categories=$category->getCategories($search_data);
         return Response::json($categories, 200);
    }

    /**
     * API for get the category data when the role is admin.
     *
     * @api {post} /api/categories/getCategoryData get the category data when the role is admin.
     * @apiDescription get the category data when the role is admin.
     *
     * @param \Illuminate\Http\Request $request All request parameters.
     *
     * @return \Illuminate\Http\Response
     */
    public function getCategoryData(Request $request)
    {
        $data = $request->json()->all(); 
        $this->logged_user = JWTAuth::parseToken()->authenticate();        
        $category =  Category::find($data['id']);
        if ($this->logged_user->role_id != env('SUPER_ADMIN')) {
            return "error";
        }
       
        return Response::json($category, 200);
    }

    /**
     * API for update the category data when the role is admin.
     *
     * @api {post} /api/categories/updateCategoryData update the category data when the role is admin.
     * @apiDescription update the category data when the role is admin.
     *
     * @param \Illuminate\Http\Request $request All request parameters.
     *
     * @return \Illuminate\Http\Response
     */
    public function updateCategoryData(Request $request)
    { 
        $this->logged_user = JWTAuth::parseToken()->authenticate();
        $data = $request->json()->all();        
        if ($this->logged_user->role_id != env('SUPER_ADMIN')) {
            return "error";
        }
        
        return $this->create($request, $data['id']);        
    }

    /**
     * API for create categories.
     *
     * @api {post} /api/categories/create create categories.
     * @apiDescription create categories.
     *
     * @param \Illuminate\Http\Request $request All request parameters.
     * @param Int                      $id      Product id.
     *
     * @return \Illuminate\Http\Response
     */
    public function create(Request $request, $id=null)
    { 
        $this->logged_user = JWTAuth::parseToken()->authenticate(); 
        $data = $request->json()->all(); 
        $category =  Category::find($id); 
        $this->status         ='error';
        $rules = [
            'category_name'  => 'required|min:3|max:25|unique:category,category_name' . ($id ? ",$id" : ''),
            'icon' => 'required'
            ];         

        $validator = \Validator::make($data, $rules);
        if ($validator->fails()) {  
            return Response::json(['status'=>$this->status, 'errors' => $validator->errors()->all()], 422); 
        } else { 
            if ($this->logged_user->role_id == env('SUPER_ADMIN')) { 
                if ($id) { 
                    $category =  Category::find($id);  
                    $msg     =  'Category has been updated';
                } else {
                    $category = new Category; 
                    $msg     =  'Category has been added';
                }
                                
            
                $category->category_name          = $data['category_name'];
                $category->icon              = $data['icon'];      

                //create category slug
                $slug = str_replace('/', ' ', $category->category_name);
                $slug = str_slug($slug, "-");
                $slugCount = 0;
                if (isset($id) && $id != null) {
                    $slugCount = count(\DB::table('category')->whereRaw("slug REGEXP '^{$slug}(-[0-9]*)?$' AND id!=".$id)->get());
                } else {
                    $slugCount = count(\DB::table('category')->whereRaw("slug REGEXP '^{$slug}(-[0-9]*)?$' ")->get());
                }
                $category->slug = ($slugCount > 0) ? "{$slug}-{$slugCount}" : $slug;
                
                $saved      =$category->save();
                $category_id = $category->id;                     
                if ($saved) { 
                    $this->success_message= $msg;
                    $this->status         ='success';
                    $done = array('status'=>$this->status, 'message'=>$this->success_message);
                    return Response::json($done, 200); 
                }
            }
            $this->success_message= 'Permission denied';
            $done = array('status'=>$this->status, 'message'=>$this->success_message);
            return Response::json($done, 401); 
        }   
    }

}
