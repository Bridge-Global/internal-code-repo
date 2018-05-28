@extends('layouts.master', ['body_class' => 'home'])

@section('content')

    <div class="content-wrapper content-home">
        <div class="col-md-12">

            <div id="HotspotPlugin_image" style="width: {{ $map_size['width'] }};height: {{ $map_size['height'] }};">
            <div id="loading-image" >
                <img src="{{ url('public/assets') }}/img/ajax-loader.gif" />
              </div>
            </div>
        </div>

        <!-- Video Player Modal -->
        <div class="modal fade video_player" id="videoModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel">
          <div class="modal-dialog" role="document">
            <div class="modal-content">
              <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true"><img src="{{ url('public/assets') }}/img/close.png" /></span></button>

              </div>
              <div class="modal-body">

                <video id="video" class="video-js vjs-default-skin vjs-big-play-centered" controls preload="none" width="100%" height="450" data-setup='{}' controlsList="nofullscreen nodownload">
                    <source data-res="480" src="" type='video/mp4' />
                    <!-- Tracks need an ending tag thanks to IE9 -->
                    <p class="vjs-no-js">To view this video please enable JavaScript, and consider upgrading to a web browser that <a href="http://videojs.com/html5-video-support/" target="_blank">supports HTML5 video</a>
                    </p>
                </video>
                <div>
                  <div class="uploaded_by"></div>
                  <div class="social_share">
                    <a href="javascript:void(0);" rel="nofollow" class="share fb" data-network="facebook"><img src="{{ url('public/assets') }}/img/facebook.png" class="logo-img" alt="facebook"></a>
                    <!-- <a href="javascript:void(0);"><img src="{{ url('public/assets') }}/img/instagram.png" class="logo-img" alt="instagram"></a> -->
                    <a href="javascript:void(0);"  class="share twitter" data-network="twitter"><img src="{{ url('public/assets') }}/img/twitter.png" class="logo-img" alt="twitter"></a>
                  </div>
                </div>
              </div>
              <div class="modal-footer">
              </div>
            </div>
          </div>
        </div>

    </div>
        
@endsection