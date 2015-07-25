<?php

namespace Hangar18\Datasources\CAA\Response;

class ReleaseGroup
{
    protected $images  = [];
    protected $release = '';
    
    public function __construct($json)
    {
        /* http://coverartarchive.org/release-group/
         *                              5cbae3a0-6d55-497b-97b3-6c30a3264313
         * {
         *  "images":
         *   [
         *    {
         *      "types":["Front"],
         *      "front":true,
         *      "back":false,
         *      "edit":26478163,
         *      "image": "http://coverartarchive.org/release/
         *                c3da7321-1905-4f3f-87e7-88cfab5f72fb/6582472249.jpg",
         *      "comment":"",
         *      "approved":true,
         *      "id":"6582472249",
         *      "thumbnails":
         *        {
         *          "large":"http://coverartarchive.org/release/c3da7321-
         *                      1905-4f3f-87e7-88cfab5f72fb/6582472249-500.jpg",
         *          "small":"http://coverartarchive.org/release/c3da7321-
         *                      1905-4f3f-87e7-88cfab5f72fb/6582472249-250.jpg"
         *        }
         *    }
         *   ],
         *  "release": "http://musicbrainz.org/release/
         *                c3da7321-1905-4f3f-87e7-88cfab5f72fb"
         * }
         */
        
        $p = \json_decode($json, true);
        if($p === null)
        {
            throw new \Exception('Error decoding JSON: '.
                                        \json_last_error_msg());
        }
        
        if( !isset($p['release'],                $p['images'][0]['image'],
                   $p['images'][0]['approved'],  $p['images'][0]['types'],
                   $p['images'][0]['thumbnails'],
                   $p['images'][0]['thumbnails'][0]['large'],
                   $p['images'][0]['thumbnails'][0]['small']) ||
            !is_array($p['images'][0]['types']) )
        {
            throw new \Exception('Malformed JSON response: '.
                                        \json_last_error_msg());
        }
        
        $this->images  = $p['images'][0];
        $this->release = $p['release'];
    }
    
    public function isApproved()
    {
        return (bool) $this->images['approved'];
    }
    
    public function getReleaseURL()
    {
        return $this->release;
    }
    
    public function getPrimaryImage()
    {
        return $this->images->image;
    }
    
    public function hasPrimaryImage()
    {
        return (\strlen($this->images['image']) > 0);
    }
    
    public function hasThumbnail($size='large')
    {
        return (isset($this->images['thumbnails'][0][$size]));
    }
    
    public function getThumbnail($size='large')
    {
        if(isset($this->images['thumbnails'][0][$size]))
        {
            return $this->images['thumbnails'][0][$size];
        }
        
        return null;
    }
}
