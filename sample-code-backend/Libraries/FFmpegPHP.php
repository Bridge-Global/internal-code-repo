<?php
/**
 * FFmpeg Class
 *
 * @category FFmpegPHP
 * @package  Library
 */

namespace App\Libraries;


class FFmpegPHP
{

    /**
     * Constructor function
     *
     * @return void
     */
    public function __construct()
    {
        
    }

    /**
     * Function to generate video from audio and static image.
     *
     * @param string $static_image      staic image.
     * @param string $audio             audio file.
     * @param string $audio_ext         audio file extension.
     * @param string $destination_video new video name.
     *
     * @return string
     */
    public function generateVideoFromAudio($static_image='', $audio='', $audio_ext='', $destination_video='')
    {
        if (empty($static_image) || empty($audio) || empty($destination_video)) {
            return true;
        }

        if ($audio_ext == 'aac' || $audio_ext == 'm4a') {
            //get audio duration
            $duration = $this->getDuration($audio);
            if ($duration) {
                if ($audio_ext == 'm4a') {
                    //get uploaded filename without extension
                    $audio_name = pathinfo($audio, PATHINFO_FILENAME);
                    $mp3_audio = public_path().'/uploads/'.$audio_name.'.mp3';
                    //convert m4a to mp3
                    exec("ffmpeg -i ".$audio." -acodec libmp3lame -aq 2 ".$mp3_audio." 2>&1", $output, $return);
                    if ($return) {
                        return true;
                    }
                    $audio = $mp3_audio;
                    exec("ffmpeg -loop 1 -i ".$static_image." -i ".$audio." -r 30 -c:v libx264 -c:a aac -strict experimental -b:a 16k -shortest ".$destination_video." 2>&1", $output, $return);
                    //remove mp3 and trimmed videos
                    if (\File::exists($audio)) {
                        \File::delete($audio); 
                    }
                } else {
                
                    exec("ffmpeg -loop 1 -i ".$static_image." -i ".$audio." -r 29.97 -c:v libx264 -tune stillimage -c:a aac -strict experimental -b:a 192k -pix_fmt yuv420p -shortest ".$destination_video." 2>&1", $output, $return);
                }


                if (!$return) {
                    //trim video to remove extra time.
                    $video_name = basename($destination_video);  
                    $trimmed_video = public_path().'/uploads/'.'trimmed_'.$video_name;
                    exec("ffmpeg -i ".$destination_video." -ss 00:00:00.000 -t ".$duration." ".$trimmed_video." 2>&1", $output1, $return1);
                    if (!$return1) {
                        if (\File::exists($destination_video)) {  
                            \File::delete($destination_video); 
                        }
                        rename($trimmed_video, $destination_video);
                        return false;
                    }
                }
            }
            return true;
        }

        exec("ffmpeg -i ".$static_image." -i ".$audio." -r 29.97 ".$destination_video." ", $output, $return);
        return $return;
    }

    /**
     * Function to create image with text.
     *
     * @param string $images_dir        staic image directory.
     * @param string $font_path         font file.
     * @param string $text              text.
     * @param string $destination_image new image.
     *
     * @return string
     */
    public function imageCreate($images_dir = '', $font_path='', $text='', $destination_image='')
    {
        if (empty($images_dir) || empty($font_path) || empty($text) || empty($destination_image)) {
            return false;
        }
        $images = glob($images_dir . '*.{jpg}', GLOB_BRACE);
        $static_image = $images[array_rand($images)]; 

        header('Content-type: image/jpeg');
        $jpg_image = imagecreatefromjpeg($static_image);
        $white = imagecolorallocate($jpg_image, 101, 20, 52);
        imagettftext($jpg_image, 12, 0, 530, 300, $white, $font_path, $text);
        imagejpeg($jpg_image, $destination_image);
        imagedestroy($jpg_image);
        return true;
    }

    /**
     * Function to convert video.
     *
     * @param string $video             video file.
     * @param string $destination_video new video name.
     *
     * @return string
     */
    public function convertVideo($video='', $destination_video='')
    {
        if (empty($video) || empty($destination_video)) {
            return false;
        }
        
        exec("ffmpeg -i ".$video." -vcodec h264 -acodec aac -strict -2 ".$destination_video." ", $output, $return);
        return $return;
    }

    /**
     * Function to get file duration.
     *
     * @param string $file file.
     *
     * @return string
     */
    public function getDuration($file='')
    {
        if (empty($file)) {
            return false;
        }
        
        exec("ffmpeg -i ".$file." 2>&1", $output, $return);
        if ($output) {
            foreach ($output as $value) {
                if (strpos(trim($value), 'Duration') === 0) {
                    $value = str_replace(',', '', trim($value));
                    $file_info = explode(' ', $value);
                    return isset($file_info[1])? $file_info[1]:false;
                }
            }
        }
        return false;
    }
}
