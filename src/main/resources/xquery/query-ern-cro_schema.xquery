declare namespace schema= "http://schema.org/";
declare namespace cro=    "http://rhizomik.net/ontologies/copyrightonto.owl#";
declare namespace ddex=   "http://rhizomik.net/ontologies/ddexonto#";
declare namespace rdf=    "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs=   "http://www.w3.org/2000/01/rdf-schema#";
declare namespace owl=    "http://www.w3.org/2002/07/owl#";
declare namespace dct=    "http://purl.org/dc/terms/";
declare namespace xsd=    "http://www.w3.org/2001/XMLSchema#";

declare variable $territories := "http://rhizomik.net/ontologies/2011/06/iso3166a2.owl#";
declare variable $currencies := "http://rhizomik.net/ontologies/2011/06/iso4217a.owl#";
declare variable $ddex := "http://rhizomik.net/ontologies/ddexonto#";
declare variable $schema := "http://schema.org/";
declare variable $cro := "http://rhizomik.net/ontologies/copyrightonto.owl#";
declare variable $rdf := "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare variable $baseURI := "http://rhizomik.net/redefer/ddex2rdf/";
declare variable $file external;
declare variable $fullPath external;
declare variable $base := concat($baseURI,local:filename($file));
(: let $file := "src/main/resources/static/ddex-samples/Sample-08.04.xml" :)

declare function local:filename($arg as xs:string?) as xs:string
{       
    replace($arg,'^.*/','')
};

declare function local:baseURI($localId as xs:string) as xs:string
{
    let $baseURI := concat($base,'#',$localId)
    return ($baseURI)
};

declare function local:getResourceURI($localId as xs:string) as xs:string
{
    let $resource := doc($file)//ResourceList/*[ResourceReference=$localId]
    
    let $resourceURI :=
        if ($resource/*/ISRC) then concat("urn:isrc:",data($resource/*/ISRC))
        else if ($resource/*/ISBN) then concat("urn:isbn:",data($resource/*/ISBN))
        else if ($resource/*/ISSN) then concat("urn:issn:",data($resource/*/ISSN))
        else if ($resource/*/SICI) then concat("urn:sici:",data($resource/*/SICI))
        else if ($resource/*/ISAN) then concat("urn:isan:",data($resource/*/ISAN))
        else if ($resource/*/VISAN) then concat("urn:visan:",data($resource/*/VISAN))
        else if ($resource/*/CatalogNumber) then concat("urn:catalog:",data($resource/*/CatalogNumber)) 
        else if ($resource/*/ProprietaryId) then concat("urn:",$resource/*/ProprietaryId/@Namespace,":",data($resource/*/ProprietaryId))
        else local:baseURI($localId)
    return ($resourceURI)
};

declare function local:getReleaseURI($localId as xs:string) as xs:string
{
    let $release := doc($file)//Release[ReleaseReference=$localId]

    let $releaseURI :=
        if ($release/ReleaseId/ISRC) then concat("urn:isrc:",data($release/ReleaseId/ISRC))
        else if ($release/ReleaseId/GRid) then concat("urn:grid:",data($release/ReleaseId/GRid))
        else if ($release/ReleaseId/ICPN) then concat("urn:icpn:",data($release/ReleaseId/ICPN))
        else if ($release/ReleaseId/CatalogNumber) then concat("urn:catalog:",data($release/ReleaseId/CatalogNumber))
        else if ($release/ReleaseId/ProprietaryId) then concat("urn:",$release/ReleaseId/ProprietaryId/@Namespace,":",data($release/ReleaseId/ProprietaryId))
        else local:baseURI($localId)
    return ($releaseURI)
};

declare function local:getPartyDescription($party)
{
    if ($party/PartyId/@Namespace) then (
      let $name := $party/PartyName/FullName/text()
      let $uri := concat("urn:", $party/PartyId/@Namespace, "/", $party/PartyId/text())
      return
      <rdf:Description rdf:about="{$uri}">
          <schema:name>{data($name)}</schema:name>
      </rdf:Description> )
    else (
      let $name := $party/PartyName/FullName/text()
      return $name )
};


declare function local:buildResource($uri, $label, $type)
{
    <rdf:Description rdf:about="{$uri}">
        <rdfs:label>{data($label)}</rdfs:label>
        <rdf:type rdf:resource="{$type}"/>
    </rdf:Description>
};

declare function local:buildLabelResource($label, $kind, $type)
{
    let $uri := concat($baseURI,$kind,"/",encode-for-uri($label))
    return
        local:buildResource($uri,$label,$type)
};

declare function local:buildLabelURI($label, $kind)
{
    let $uri := concat($baseURI,$kind,"/",encode-for-uri($label))
    return $uri
};

for $resource at $i in doc($file)//ResourceList/SoundRecording
    let $resourceId := local:getResourceURI(data($resource/ResourceReference))
    let $resourceDetails := $resource/*[contains(local-name(.),"DetailsByTerritory")][1]
    let $technicalDetails := $resourceDetails/*/TechnicalResourceDetailsReference/..
    return
    <schema:MusicRecording rdf:about="{$resourceId}">
        { if ($resource/*/ISRC) then <schema:identifier>{data($resource/*/ISRC)}</schema:identifier> else () }
        { if ($resource/*/ISBN) then <schema:identifier>{data($resource/*/ISBN)}</schema:identifier> else () }
        { if ($resource/*/ISSN) then <schema:identifier>{data($resource/*/ISSN)}</schema:identifier> else () }
        { if ($resource/*/SICI) then <schema:identifier>{data($resource/*/SICI)}</schema:identifier> else () }
        { if ($resource/*/ISAN) then <schema:identifier>{data($resource/*/ISAN)}</schema:identifier> else () }
        { if ($resource/*/VISAN) then <schema:identifier>{data($resource/*/VISAN)}</schema:identifier> else () }
        { if ($resource/*/CatalogNumber) then <schema:identifier>{data($resource/*/CatalogNumber)}</schema:identifier> else () }
        { if ($resource/*/ProprietaryId) then <schema:identifier>{data($resource/*/ProprietaryId/@Namespace)}-{data($resource/*/ProprietaryId)}</schema:identifier> else () }
        { for $title in $resource/(ReferenceTitle|Title)/TitleText
            return <schema:name>{data($title)}</schema:name> }
        { for $altTitle in $resource/(ReferenceTitle|Title)/SubTitle 
            return <schema:alternativeHeadline>{data($altTitle)}</schema:alternativeHeadline> }
        { for $duration in $resource/Duration 
            return <schema:duration>{data($duration)}</schema:duration> }
        { for $language in $resource/LanguageOfPerformance 
            return <schema:inLanguage>{data($language)}</schema:inLanguage> }
        { for $creator in $resourceDetails/DisplayArtist 
            return <schema:creator>{local:getPartyDescription($creator)}</schema:creator> }
        { for $copyrightYear in $resourceDetails/(CLine|PLine)/Year
            return <schema:copyrightYear>{data($copyrightYear)}</schema:copyrightYear> }
        { for $copyright in $resourceDetails/(CLine|PLine)/(CLineText|PLineText)
            return <dct:copyright>{data($copyright)}</dct:copyright> }
        { for $label in distinct-values($resourceDetails/LabelName)
            return <schema:recordLabel>{data($label)}</schema:recordLabel> }
        { for $genre in $resourceDetails/Genre/GenreText
            return <schema:genre>{data($genre)}</schema:genre> }
        { for $parental in $resourceDetails/ParentalWarningType
            return <schema:contentRating>{data($parental)}</schema:contentRating> }
    </schema:MusicRecording>,

for $release at $i in doc($file)//ReleaseList/Release[ReleaseType="Album"]
    let $releaseId :=
        if ($release/ReleaseReference) then local:getReleaseURI(data($release/ReleaseReference))
        else if ($release/ReleaseId/GRid) then local:getReleaseURI(data($release/ReleaseId/GRid))
        else if ($release/ReleaseId/ICPN) then local:getReleaseURI(data($release/ReleaseId/ICPN))
        else local:buildLabelURI($release/ReferenceTitle/TitleText, "release")
    let $releaseDetails := $release/ReleaseDetailsByTerritory[1]
    return
    <schema:MusicAlbum rdf:about="{$releaseId}">
        { if ($release/ReleaseId/GRid) then <schema:identifier>{data($release/ReleaseId/GRid)}</schema:identifier> else () }
        { if ($release/ReleaseId/ISRC) then <schema:identifier>{data($release/ReleaseId/ISRC)}</schema:identifier> else () }
        { if ($release/ReleaseId/ICPN) then <schema:identifier>{data($release/ReleaseId/ICPN)}</schema:identifier> else () }
        { if ($release/ReleaseId/CatalogNumber) then <schema:identifier>{data($release/ReleaseId/CatalogNumber)}</schema:identifier> else () }
        { if ($release/ReleaseId/ProprietaryId) then <schema:identifier>{data($release/ReleaseId/ProprietaryId/@Namespace)}-{data($release/ReleaseId/ProprietaryId)}</schema:identifier> else () }
        { for $title in $release/(ReferenceTitle|Title)/TitleText
            return <schema:name>{data($title)}</schema:name> }
        { for $altTitle in $release/ReferenceTitle/SubTitle
            return <schema:alternativeHeadline>{data($altTitle)}</schema:alternativeHeadline> }
        { for $duration in $release/Duration
            return <schema:duration>{data($duration)}</schema:duration> }
        { for $copyrightYear in $release/(CLine|PLine)/Year
            return <schema:copyrightYear>{data($copyrightYear)}</schema:copyrightYear> }
        { for $copyright in $release/(CLine|PLine)/(CLineText|PLineText)
            return <dct:copyright>{data($copyright)}</dct:copyright> }
        { for $resource in $release/ReleaseResourceReferenceList/ReleaseResourceReference
            return <schema:track rdf:resource="{local:getResourceURI(data($resource))}"/> }
        { for $creator in $releaseDetails/DisplayArtist
            return <schema:creator>{local:getPartyDescription($creator)}</schema:creator> }
        { for $genre in $releaseDetails/Genre/GenreText
            return <schema:genre>{data($genre)}</schema:genre> }
        { for $releaseDate in $release/ReleaseDetailsByTerritory/OriginalReleaseDate[1]
            return <schema:datePublished>{data($releaseDate)}</schema:datePublished> }
    </schema:MusicAlbum>,

for $deal at $i in doc($file)//DealTerms
    let $dealId := local:baseURI(concat("deal-",$i))
    return
<cro:Agree rdf:about="{$base}">
    { if ($deal/../../EffectiveDate) then <cro:pointInTime>{data($deal/../../EffectiveDate)}</cro:pointInTime> else () }
    <schema:object>
        <rdf:Description rdf:about="{$dealId}">
        { for $use in $deal/Usage/UseType return
            if ($use!="UserDefined") then <rdf:type rdf:resource="{concat($ddex,$use)}"/>
            else <rdf:type rdf:resource="{concat($ddex,replace($use/@UserDefinedValue,' ',''))}"/>
        }
        {
          for $releaseRef in $deal/../../DealReleaseReference
              return <schema:object rdf:resource="{local:getReleaseURI($releaseRef)}"/>,
          for $releaseId in $deal/../../ReleaseId/GRid
              return <schema:object rdf:resource="{concat("urn:grid:",$releaseId)}"/>
        }
        { for $party in $deal/DistributionChannel return
            ( if ($party/PartyId) then
                <schema:agent rdf:resource="{concat("urn:party:",data($deal/DistributionChannel/PartyId))}"/>
              else if ($party/PartyName/FullName) then
                <schema:agent rdf:resource="{concat("urn:party:",data($deal/DistributionChannel/PartyName/FullName))}"/>
              else ()
            )
        }
        { for $territory in $deal/TerritoryCode return
            <schema:location rdf:resource="{concat($territories, $territory)}"/>
        }
        { if (count($deal/ValidityPeriod)>0) then
               ( if ($deal/ValidityPeriod/StartDate[1]) then
                    <cro:start>{data($deal/ValidityPeriod/StartDate[1])}</cro:start> else (),
                 if ($deal/ValidityPeriod/EndDate[1]) then
                    <cro:completion>{data($deal/ValidityPeriod/EndDate[1])}</cro:completion> else () ) else ()
        }
        { for $instrument in $deal/Usage/UserInterfaceType return (: PersonalComputer, PortableDevice,... :)
            <schema:instrument>{data($instrument)}</schema:instrument>
        }
        { for $medium in $deal/Usage/DistributionChannelType return (: Internet,... :)
            <schema:instrument>{data($medium)}</schema:instrument>
        }
        { for $crommercialModel in $deal/CommercialModelType return (: PayAsYouGoModel,... :)
            <cro:how rdf:resource="{concat($ddex,$crommercialModel,'Value')}"/>
        }
        { for $priceInfo in $deal/PriceInformation/*
            let $priceId := if ($priceInfo/@Namespace) then
              concat("urn:", $priceInfo/@Namespace, "/", data($priceInfo)) else ()
            return
            <cro:condition>
                <rdf:Description>
                    { if ($priceId) then
                        attribute rdf:about { $priceId } else()
                    }
                    <rdf:type rdf:resource="{concat($ddex,node-name($priceInfo))}"/>
                    { if (not($priceId)) then
                      <rdf:value>{data($priceInfo)}</rdf:value> else ()
                    }
                    { if ($priceInfo/@CurrencyCode) then
                      <cro:currency rdf:resource="{concat($currencies,$priceInfo/@CurrencyCode)}"/> else ()
                    }
                </rdf:Description>
            </cro:condition>
        }
        </rdf:Description>
    </schema:object>
</cro:Agree>