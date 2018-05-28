<?php
/**
 * Audios Controller
 *
 * @category AudiosController
 * @package  Controller
 */

namespace App\Http\Controllers;

use Illuminate\Http\Request;

use App\Http\Requests;
use Lang;
use Config;
use Response;
use App\Media;
use App\Key;
use App\Libraries\GenerateHashId;
use App\Libraries\Word2Uni;
use App\Libraries\FFmpegPHP;
use App\Libraries\amazonS3;
use App\Validators\CustomValidator;


class AudiosController extends Controller
{
    /**
     * Index.
     *
     * @return \Illuminate\Http\Response
     */
    public function index()
    {
        //
    }

    /**
     * API for uploading audio.
     *
     * @api {post} /api/audio Convert audio to video and store in aws s3 bucket.
     * @apiDescription convert audio to video mp4 format with static image and uploads video to aws s3.
     *
     * @apiSuccessExample 
     * {
     *  "status": "success",
     *  "message": "Video created successfully.",
     *  "data":{
     *      "url": "",
     *      "web_url": "",
     *      "id":""
     *  }
     * }
     *
     * @apiParam
     * (Required) (file) file Audio file
     * (Required) (string) username Name of user who uploaded file
     * (Required) (string) api_key API Key
     *
     * @param \Illuminate\Http\Request $request All request parameters.
     *
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {
        $mime_type = '';
        if ($request->hasFile('file')) {
            $mime_type = $request->file('file')->getClientMimeType();
        }
        $customvalidator = new CustomValidator;
        $validator = $customvalidator->validateMedia($request->all(), 'audio', $mime_type);

        if ($validator->fails()) {
            $failedRules=$validator->failed();
            return Response::json(
                array(
                'status' => 'failure',
                'message' => $validator->errors()->first()
                ), 400
            );
        }
        
        if ($request->hasFile('file')) {
            $file = $request->file('file');
            
            $audio_name = $file->getClientOriginalName();
            $audio_path = $file->getPathName();
            $audio_ext = $file->getClientOriginalExtension();

            //create video mp4 from audio.
            //get random image from folder.
            $images_dir = Config::get('constants.random_image_path');
            //Add author name to image.
            $author_image = Config::get('constants.temp_path')."/test.jpg";
            $text = $request->input('uploaded_by');
            
            //check name is arabic or not.
            $is_arabic = preg_match('/\p{Arabic}/u', $text);
            if ($is_arabic) {
                //check if multiwords
                $multi_words = explode(' ', $text);
                $word2uni = new Word2Uni();
                $arabic_words = [];
                foreach ($multi_words as $word) {
                    $is_word_arabic = preg_match('/\p{Arabic}/u', $word);
                    $arabic_words[] = ($is_word_arabic)? $word2uni->word2unichar($word):$word;
                }
                //$text = implode(' ', array_reverse($arabic_words));
                $text = implode(' ', $arabic_words);
            }
            $font_path = Config::get('constants.font_path').'/arial.ttf';           
            $video_name = 'vid-'.date('dmyhis').'-'.str_random(10).'.mp4';
            $video_path = public_path().'/uploads/'.$video_name ;
            
            $ffmpeg = new FFmpegPHP();
            $ffmpeg->imageCreate($images_dir, $font_path, $text, $author_image);
            //$return = $ffmpeg->generateVideoFromAudio($author_image, $audio_path, $video_path);
            $return = $ffmpeg->generateVideoFromAudio($author_image, $audio_path, $audio_ext, $video_path);
            unlink($author_image);
            
            if (!$return) {
                //upload to s3.
                $s3 = new amazonS3();
                $url = $s3->uploadFile($video_name, $video_path);
                if ($url) {
                    //generate random hash id.
                    $generatehshid = new GenerateHashId();
                    $hash_id = $generatehshid->getToken(16);

                    //save in db
                    $media = new Media();
                    $media->name = $video_name;
                    $media->url = $url;
                    $media->uploaded_by = trim($request->input('uploaded_by'));
                    $media->email = trim($request->input('email'));
                    $media->type = 'audio';
                    $media->hash_id = $hash_id;
                    $result = $media->save();

                    $web_url = url('/video/').'/'.$hash_id;

                    if ($result) {
                        return Response::json(
                            array(
                            'status' => 'success',
                            'message' => Lang::get('api.video_created'),
                            'data' => array('url'=>$url,'web_url'=>$web_url,'id'=>strval($media->id)),
                            ), 201
                        );
                    } 
                }

                return Response::json(
                    array(
                    'status' => 'failure',
                    'message'=> Lang::get('api.failed_to_store_s3')
                    ), 422
                );  
                
            }
            return Response::json(
                array(
                    'status' => 'failure',
                    'message'=> Lang::get('api.failed_to_convert_audio')
                ), 422
            );  
                      
        }
        return Response::json(
            array(
            'status' => 'failure',
            'message'=> Lang::get('api.unauthorized_access')
            ), 401
        );
    }

}
