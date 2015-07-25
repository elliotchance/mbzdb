<?php

namespace Hangar18\Datasources\CAA\Request;

use Hangar18\Datasources\CAA\AbstractRequest;
use Hangar18\Datasources\CAA\Response\ReleaseGroup as ReleaseGroupResponse;

class ReleaseGroup extends AbstractRequest
{
    /**
     * Request URI (relative to http://coverartarchive.org)
     * @var string
     */
    protected $uri;
    
    /**
     * Gets the HTTP URI for the API request.
     * 
     * @param string $mbid Release Group MusicBrainz  global ID
     * @return \Hangar18\Datasources\CAA\Request\ReleaseGroup
     */
    public static function getReleaseGroupInfoRequestByMBID($mbid)
    {
        $ret = new self;
        
        $ret->uri = "/release-group/{$mbid}";
        return $ret;
    }
    
    public function getRequestURI()
    {
        return $this->uri;
    }
    
    /**
     * Parses the JSON data returned by the API and returns a response object.
     * 
     * @param string $json JSON data
     * @return Hangar18\Datasources\CAA\Response\ReleaseGroup
     */
    public static function parseResponse($json)
    {
        return new ReleaseGroupResponse($json);
    }
}
