declare namespace ddex=     "http://rhizomik.net/ontologies/2011/06/ddex.owl#";
declare namespace currency= "http://rhizomik.net/ontologies/2011/06/iso4217a.owl#";
declare namespace territory="http://rhizomik.net/ontologies/2011/06/iso3166a2.owl#";
declare namespace language= "http://rhizomik.net/ontologies/2011/06/iso639a2.owl#";
declare namespace cro=       "http://rhizomik.net/ontologies/copyrightonto.owl#";
declare namespace rdf=      "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs=     "http://www.w3.org/2000/01/rdf-schema#";
declare namespace owl=      "http://www.w3.org/2002/07/owl#";
declare namespace foaf=     "http://xmlns.com/foaf/0.1/";
declare namespace dct=      "http://purl.org/dc/terms/";
declare namespace xsd=      "http://www.w3.org/2001/XMLSchema#";
declare namespace ma=       "http://www.w3.org/ns/ma-ont#";

declare variable $ma := "http://www.w3.org/ns/ma-ont#";
declare variable $ddex := "http://rhizomik.net/ontologies/2011/06/ddex.owl#";
declare variable $currencies := "http://rhizomik.net/ontologies/2011/06/iso4217a.owl#";
declare variable $territories := "http://rhizomik.net/ontologies/2011/06/iso3166a2.owl#";
declare variable $languages := "http://rhizomik.net/ontologies/2011/06/iso639a2.owl#";
declare variable $cro := "http://rhizomik.net/ontologies/copyrightonto.owl#";
declare variable $rdf := "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare variable $file external;
declare variable $fullPath external;
declare variable $baseURI := "http://mediamixer.eu/copyright/examples/";
declare variable $base := concat($baseURI,local:filename($file));

declare function local:filename($arg as xs:string?) as xs:string
{       
    replace($arg,'^.*/','')
};

declare function local:basePath($arg as xs:string?) as xs:string
{       
    if (matches($arg, '/'))
    then replace($arg, '^(.*)/.*', '$1')
    else ''
};

declare function local:baseURI($localId as xs:string) as xs:string
{
    let $baseURI := concat($base,'#',$localId)
    return ($baseURI)
};

declare function local:getReleaseURI($localId as xs:string) as xs:string
{
    let $release := doc($file)//Release[ReleaseReference=$localId]
    
    let $releaseURI :=
        if ($release/ReleaseId/GRid) then concat("urn:grid:",data($release/ReleaseId/GRid))
        else if ($release/ReleaseId/ISRC) then concat("urn:isrc:",data($release/ReleaseId/ISRC))
        else if ($release/ReleaseId/ICPN) then concat("urn:icpn:",data($release/ReleaseId/ICPN))
        else if ($release/ReleaseId/CatalogNumber) then concat("urn:catalog:",data($release/ReleaseId/CatalogNumber)) 
        else if ($release/ReleaseId/ProprietaryId) then concat("urn:",$release/ReleaseId/ProprietaryId/@Namespace,":",data($release/ReleaseId/ProprietaryId))
        else local:baseURI($localId)
    return ($releaseURI)
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

declare function local:getReleaseResourcesURIs($localId as xs:string) as xs:string*
{
    let $release := doc($file)//Release[ReleaseReference=$localId]
    let $releaseType := $release/ReleaseType
    let $resourcesURIs := 
        if ($releaseType="Album" or $releaseType="Bundle") then ()
        else for $resource in $release/ReleaseResourceReferenceList/ReleaseResourceReference return local:getResourceURI(data($resource))
    return ($resourcesURIs)
};

declare function local:buildResource($uri, $label, $type)
{
    <rdfs:Resource rdf:about="{$uri}">
        <rdfs:label>{data($label)}</rdfs:label>
        <rdf:type rdf:resource="{$type}"/>
    </rdfs:Resource>
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

declare function local:hasValue($property, $value)
{
    (: For the DDEX Ontology, use instances instead of classes for hasValue restrictions :)
    
    let $valueRestriction := if (contains($value,"ddex.owl")) then concat($value,"Value") else $value
    return
    <owl:Restriction>
        <owl:onProperty rdf:resource="{$property}"/>
        <owl:hasValue rdf:resource="{$valueRestriction}"/>
    </owl:Restriction>
};

declare function local:someValuesFrom($property, $value)
{    
    <owl:Restriction>
        <owl:onProperty rdf:resource="{$property}"/>
        <owl:someValuesFrom rdf:resource="{$value}"/>
    </owl:Restriction>
};

declare function local:hasDatatypeValue($property, $value)
{
    <owl:Restriction>
        <owl:onProperty rdf:resource="{$property}"/>
        <owl:hasValue>{$value}</owl:hasValue>
    </owl:Restriction>
};

declare function local:timeRange($start, $end)
{
    <owl:Restriction>
        <owl:allValuesFrom>
          <rdfs:Datatype>
            <owl:onDatatype rdf:resource="http://www.w3.org/2001/XMLSchema#date"/>
            <owl:withRestrictions rdf:parseType="Collection">
            { if ($start) then 
              <rdf:Description>
                <xsd:minInclusive>{$start}</xsd:minInclusive>
              </rdf:Description> else () }
            { if ($end) then 
              <rdf:Description>
                <xsd:maxInclusive>{$end}</xsd:maxInclusive>
              </rdf:Description> else () }  
            </owl:withRestrictions>
          </rdfs:Datatype>
        </owl:allValuesFrom>
        <owl:onProperty rdf:resource="http://rhizomik.net/ontologies/2008/05/copyrightonto.owl#pointInTime"/>
    </owl:Restriction>
};

for $resource at $i in doc($file)//ResourceList/*
    let $resourceId := local:getResourceURI(data($resource/ResourceReference))
    let $resourceDetails := $resource/*[contains(local-name(.),"DetailsByTerritory")][1]
    let $technicalDetails := $resourceDetails/*/TechnicalResourceDetailsReference/..
    return
    <rdf:Description rdf:about="{$resourceId}">
        { if ($resource/*/ISRC) then <ddex:isrc>{data($resource/*/ISRC)}</ddex:isrc> else () }
        { if ($resource/*/ISBN) then <ddex:isbn>{data($resource/*/ISBN)}</ddex:isbn> else () }
        { if ($resource/*/ISSN) then <ddex:issn>{data($resource/*/ISSN)}</ddex:issn> else () }
        { if ($resource/*/SICI) then <ddex:sici>{data($resource/*/SICI)}</ddex:sici> else () }
        { if ($resource/*/ISAN) then <ddex:isan>{data($resource/*/ISAN)}</ddex:isan> else () }
        { if ($resource/*/VISAN) then <ddex:visan>{data($resource/*/VISAN)}</ddex:visan> else () }
        { if ($resource/*/CatalogNumber) then <ddex:catalogNumber>{data($resource/*/CatalogNumber)}</ddex:catalogNumber> else () }
        { if ($resource/*/ProprietaryId) then <ddex:propietaryId>{data($resource/*/ProprietaryId/@Namespace)}-{data($resource/*/ProprietaryId)}</ddex:propietaryId> else () }
        { for $type in $resource/(SoundRecordingType|MidiType|VideoType|ImageType|TextType) 
            return <rdf:type rdf:resource="{concat($ddex,$type)}"/> }
        { for $title in $resource/(ReferenceTitle|Title)/TitleText 
            return ( <dct:title>{data($title)}</dct:title>, <rdfs:label>{data($title)}</rdfs:label> ) }
        { for $altTitle in $resource/(ReferenceTitle|Title)/SubTitle 
            return <dct:alternative>{data($altTitle)}</dct:alternative> }
        { for $duration in $resource/Duration 
            return <dct:extent>{data($duration)}</dct:extent> }
        { for $language in $resource/LanguageOfPerformance 
            return <dct:language>{data($language)}</dct:language> }
        { for $creator in $resourceDetails/DisplayArtist 
            return <dct:creator>{local:buildLabelResource($creator/PartyName[not(@LanguageAndScriptCode)]/FullName, "person",
                                                         concat($cro,"LegalPerson"))}</dct:creator> }
        { for $cropyright in $resourceDetails/(CLine|PLine)/(CLineText|PLineText) 
            return <dct:copyright>{data($cropyright)}</dct:copyright> }
        { for $label in $resourceDetails/LabelName
            return <dct:publisher rdf:resource="{local:buildLabelURI(data($label), "label")}"/> }
        { for $genre in $resourceDetails/Genre/GenreText
            return <ma:hasGenre>{data($genre)}</ma:hasGenre> }
        { for $parental in $resourceDetails/ParentalWarningType
            return <ddex:parentalWarning rdf:resource="{concat($ddex,$parental)}"/> }
        { for $technicalDetail in $technicalDetails 
            return
                <cro:hasInstance>
                    <cro:Instance rdf:about="{local:buildLabelURI(data($technicalDetail/File/FileName),"file")}">
                        <rdfs:label>{data($technicalDetail/File/FileName)}</rdfs:label>
                        <ddex:path>{concat(local:basePath($fullPath),'/resources/',data($technicalDetail/File/FileName))}</ddex:path>
                        { for $audioFormat in $technicalDetail/AudioCodecType 
                            return <dct:format rdf:resource="{concat($ddex,$audioFormat)}"/> }
                        { for $imageFormat in $technicalDetail/ImageCodecType 
                            return <dct:format rdf:resource="{concat($ddex,$imageFormat)}"/> }
                        { for $videoFormat in $technicalDetail/VideoCodecType 
                            return if (data($videoFormat)="UserDefined" and data($videoFormat/@UserDefinedValue)="MPEG2")
                                then <dct:format rdf:resource="{concat($ddex,"MPEG-2")}"/>
                                else <dct:format rdf:resource="{concat($ddex,$videoFormat)}"/> }
                        { for $bitrate in $technicalDetail/BitRate
                            return <ma:averageBitRate>{data($bitrate)}</ma:averageBitRate> }
                        { for $channels in $technicalDetail/NumberOfChannels
                            return <ma:numberOfTracks>{data($channels)}</ma:numberOfTracks> }
                        { for $samplingRate in $technicalDetail/SamplingRate
                            return <ma:samplingRate>{data($samplingRate)} {data($samplingRate/@UnitOfMeasure)}</ma:samplingRate> }
                        { for $isPreview in $technicalDetail/IsPreview
                            return <ddex:isPreview>{data($isPreview)}</ddex:isPreview> }
                        { for $height in $technicalDetail/ImageHeight
                            return <ma:frameHeight>{data($height)}</ma:frameHeight> }
                        { for $width in $technicalDetail/ImageWidth
                            return <ma:frameWidth>{data($width)}</ma:frameWidth> }
                    </cro:Instance>
                </cro:hasInstance> }
    </rdf:Description>,

for $release at $i in doc($file)//ReleaseList/Release
(: { for $role in $creator/ArtistRole return <rdf:type rdf:resource="{concat($ddex,$role)}"/> } :)
(: Just get the PartyName version without language code :)

    let $releaseId :=
        if ($release/ReleaseReference) then local:getReleaseURI(data($release/ReleaseReference))
        else if ($release/ReleaseId/GRid) then local:getReleaseURI(data($release/ReleaseId/GRid))
        else if ($release/ReleaseId/ICPN) then local:getReleaseURI(data($release/ReleaseId/ICPN))
        else local:buildLabelURI($release/ReferenceTitle/TitleText, "release")
    let $releaseDetails := $release/ReleaseDetailsByTerritory[1]
    return
    <rdf:Description rdf:about="{$releaseId}">
        { if ($release/ReleaseId/GRid) then <ddex:grid>{data($release/ReleaseId/GRid)}</ddex:grid> else () }
        { if ($release/ReleaseId/ISRC) then <ddex:isrc>{data($release/ReleaseId/ISRC)}</ddex:isrc> else () }
        { if ($release/ReleaseId/ICPN) then <ddex:icpn>{data($release/ReleaseId/ICPN)}</ddex:icpn> else () }
        { if ($release/ReleaseId/CatalogNumber) then <ddex:catalogNumber>{data($release/ReleaseId/CatalogNumber)}</ddex:catalogNumber> else () }
        { if ($release/ReleaseId/ProprietaryId) then <ddex:propietaryId>{data($release/ReleaseId/ProprietaryId/@Namespace)}-{data($release/ReleaseId/ProprietaryId)}</ddex:propietaryId> else () }
        { for $type in $release/ReleaseType 
            return <rdf:type rdf:resource="{concat($ddex,$type)}"/> }
        { for $title in $release/(ReferenceTitle|Title)/TitleText 
            return ( <dct:title>{data($title)}</dct:title>, <rdfs:label>{data($title)}</rdfs:label> ) }
        { for $altTitle in $release/ReferenceTitle/SubTitle 
            return <dct:alternative>{data($altTitle)}</dct:alternative> }
        { for $duration in $release/Duration 
            return <dct:extent>{data($duration)}</dct:extent> }
        { for $cropyright in $release/(CLine|PLine)/(CLineText|PLineText) 
            return <dct:copyright>{data($cropyright)}</dct:copyright> }
        { for $resource in $release/ReleaseResourceReferenceList/ReleaseResourceReference 
            return <cro:hasPart rdf:resource="{local:getResourceURI(data($resource))}"/> }
        { for $creator in $releaseDetails/DisplayArtist 
            return <dct:creator>{local:buildLabelResource($creator/PartyName[not(@LanguageAndScriptCode)]/FullName, "person",
                                                         concat($cro,"LegalPerson"))}</dct:creator> }
        { for $label in $releaseDetails/LabelName
            return <dct:publisher>{local:buildLabelResource(data($label), "person", concat($cro,"LegalPerson"))}</dct:publisher> }
        { for $genre in $releaseDetails/Genre/GenreText
            return <ddex:genre>{data($genre)}</ddex:genre> }
        { for $releaseDate in $release/ReleaseDetailsByTerritory/OriginalReleaseDate[1]
            return <dct:issued>{data($releaseDate)}</dct:issued> }
            </rdf:Description>,

for $deal at $i in doc($file)//DealTerms
    let $dealId := local:baseURI(concat("deal-",$i))
    return
<cro:Agree rdf:about="{$base}">
    { if ($deal/../../EffectiveDate) then <cro:pointInTime>{data($deal/../../EffectiveDate)}</cro:pointInTime> else () }
    <cro:theme>
        <owl:Class rdf:about="{$dealId}">
            { for $use in $deal/Usage/UseType return
                if ($use!="UserDefined") then <rdf:type rdf:resource="{concat($ddex,$use)}"/>
                else <rdf:type rdf:resource="{concat($baseURI,replace($use/@UserDefinedValue,' ',''))}"/>
            }
            <owl:intersectionOf rdf:parseType="Collection">
            { if (count($deal/Usage/UseType)=1) then
                <owl:Class rdf:about="{concat($ddex,$deal/Usage/UseType)}"/>
              else
                <owl:Class>
                    <owl:unionOf rdf:parseType="Collection">
                    { for $use in $deal/Usage/UseType return
                        if ($use!="UserDefined") then <owl:Class rdf:about="{concat($ddex,$use)}"/>
                        else <owl:Class rdf:about="{concat($baseURI,replace($use/@UserDefinedValue,' ',''))}"/>
                    }
                    </owl:unionOf>
                </owl:Class>
            }
            {
              let $themesList := (
                for $releaseRef in $deal/../../DealReleaseReference
                    return (<owl:Thing rdf:about="{local:getReleaseURI($releaseRef)}"/>,
                           for $resourceId in local:getReleaseResourcesURIs($releaseRef) 
                                return <owl:Thing rdf:about="{$resourceId}"/> ),
                for $releaseId in $deal/../../ReleaseId/GRid
                    return <owl:Thing rdf:about="{concat("urn:grid:",$releaseId)}"/>)
              return
                if (count($themesList)=1) then
                    local:hasValue(concat($cro,"theme"),local:getReleaseURI($deal/../../DealReleaseReference))
                else if (count($themesList)>1) then
                    <owl:Restriction>
                        <owl:someValuesFrom>
                            <owl:Class>
                                <owl:oneOf rdf:parseType="Collection">
                                    {$themesList}
                                </owl:oneOf>
                            </owl:Class>                           
                        </owl:someValuesFrom>
                        <owl:onProperty rdf:resource="{concat($cro,"theme")}"/> 
                    </owl:Restriction>
                else ()
            }
            { if (count($deal/DistributionChannel)<=1) then
                ( if ($deal/DistributionChannel/PartyId) then local:hasValue(concat($cro,"agent"),concat("urn:party:",data($deal/DistributionChannel/PartyId))) else (),
                  if ($deal/DistributionChannel/PartyName/FullName) then local:hasValue(concat($cro,"agent"),concat("urn:party:",data($deal/DistributionChannel/PartyName/FullName))) else ()
                )
              else
                <owl:Class>
                    <owl:unionOf rdf:parseType="Collection">
                        { for $partyId in $deal/DistributionChannel/PartyId
                            return local:hasValue(concat($cro,"agent"),concat("urn:party:",data($partyId))) }
                        { for $partyName in $deal/DistributionChannel/PartyName/FullName
                            return local:hasValue(concat($cro,"agent"),concat("urn:party:",data($partyName))) }
                    </owl:unionOf>
                </owl:Class>
            }
            { if (count($deal/Usage/UserInterfaceType)<=1) then
                ( if ($deal/Usage/UserInterfaceType) then local:someValuesFrom(concat($cro,"instrument"),concat($ddex,$deal/Usage/UserInterfaceType)) else () )
              else
                <owl:Class>
                    <owl:unionOf rdf:parseType="Collection">
                        { for $userInterface in $deal/Usage/UserInterfaceType
                            return local:someValuesFrom(concat($cro,"instrument"),concat($ddex,$userInterface)) }
                    </owl:unionOf>
                </owl:Class>
            }
            { if (count($deal/Usage/DistributionChannelType)<=1) then
                ( if ($deal/Usage/DistributionChannelType) then local:someValuesFrom(concat($cro,"medium"),concat($ddex,$deal/Usage/DistributionChannelType)) else () )
              else
                <owl:Class>
                    <owl:unionOf rdf:parseType="Collection">
                        { for $distributionChannel in $deal/Usage/DistributionChannelType
                            return local:someValuesFrom(concat($cro,"medium"),concat($ddex,$distributionChannel)) }
                    </owl:unionOf>
                </owl:Class>
            }
            { if (count($deal/TerritoryCode)=1) then
                    local:hasValue(concat($cro,"location"),concat($territories,$deal/TerritoryCode))
              else if (count($deal/TerritoryCode)>1) then
                  <owl:Restriction>
                      <owl:someValuesFrom>
                          <owl:Class>
                              <owl:oneOf rdf:parseType="Collection">
                                  { for $territory in $deal/TerritoryCode
                                        return <owl:Thing rdf:about="{concat($territories,$territory)}"/> }
                              </owl:oneOf>
                          </owl:Class>                           
                      </owl:someValuesFrom>
                      <owl:onProperty rdf:resource="{concat($cro,"location")}"/> 
                  </owl:Restriction>
              else ()
            }
            </owl:intersectionOf>
        { for $crommercialModel in $deal/CommercialModelType return 
            <cro:aim rdf:resource="{concat($ddex,$crommercialModel,'Value')}"/> 
        }
        { if (count($deal/ValidityPeriod)>0) then
               ( if ($deal/ValidityPeriod/StartDate[1]) then
                    <cro:start>{data($deal/ValidityPeriod/StartDate[1])}</cro:start> else (),
                 if ($deal/ValidityPeriod/EndDate[1]) then 
                    <cro:completion>{data($deal/ValidityPeriod/EndDate[1])}</cro:completion> else () ) else ()
        }
        { for $priceInfo in $deal/PriceInformation/* return 
            <cro:condition>
                <owl:Class>
                    <rdf:type rdf:resource="{concat($ddex,node-name($priceInfo))}"/>
                    <rdf:value>{data($priceInfo)}</rdf:value>
                    <cro:currency rdf:resource="{concat($currencies,$priceInfo/@CurrencyCode)}"/>
                    <owl:intersectionOf rdf:parseType="Collection">
                        <owl:Class rdf:about="{concat($ddex,node-name($priceInfo))}"/>
                        { local:hasDatatypeValue(concat($rdf,"value"),data($priceInfo)) }
                        { if ($priceInfo/@CurrencyCode) then local:hasValue(concat($cro,"currency"),concat($currencies,$priceInfo/@CurrencyCode)) else () }
                    </owl:intersectionOf>
                </owl:Class>
            </cro:condition> }
        </owl:Class>
    </cro:theme>
</cro:Agree>

    (: TODO: take into account Deals with multiple time intervals :)
    (: TODO: deal with CatalogNumbers :)
    (: TODO: DealTechnicalResourceDetailsReferenceList :)
    (: TODO: consider specifics for PriceRangeType and PriceType :)   
    (: TODO: deal with ResourceUsages :)
    (: TODO: isExclusive, AllDealsCancelled (rare), TakeDown (specific right or just everything down?), ExcludedTerritoryCode (not common) :)
    
(: If no custom datatypes, model validity period using properties and values :)
(: Otherwise, model timerange using custom datatype:

           { if (count($deal/ValidityPeriod)<=1) then
                ( if ($deal/ValidityPeriod) then local:timeRange(data($deal/ValidityPeriod/StartDate),data($deal/ValidityPeriod/EndDate)) else () )
              else
                <owl:Class>
                    <owl:unionOf rdf:parseType="Collection">
                        { for $period in $deal/ValidityPeriod
                            return local:timeRange(data($period/StartDate),data($period/EndDate)) }
                    </owl:unionOf>
                </owl:Class>
            } 
:)

(: Model CommercialModelType as a Restriction as alternative to modelling it using a property-value:

            { if (count($deal/CommercialModelType)<=1) then
                ( if ($deal/CommercialModelType) then local:hasValue(concat($cro,"aim"),concat($ddex,$deal/CommercialModelType)) else () )
              else
                <owl:Class>
                    <owl:unionOf rdf:parseType="Collection">
                        { for $crommercialModel in $deal/CommercialModelType
                            return local:hasValue(concat($cro,"aim"),concat($ddex,$crommercialModel)) }
                    </owl:unionOf>
                </owl:Class>
            }
:)
                
(: Model multiple themes as union of restriction, as alternative to model just one restriction with someValuesFrom a oneOf
            {
              let $themeRestrictions := (
                for $releaseRef in $deal/../../DealReleaseReference
                    return (local:hasValue(concat($cro,"theme"),local:getReleaseURI($releaseRef)),
                            for $resourceId in local:getReleaseResourcesURIs($releaseRef) 
                                return local:hasValue(concat($cro,"theme"),$resourceId)),
                for $releaseId in $deal/../../ReleaseId/GRid
                    return local:hasValue(concat($cro,"theme"),concat("urn:grid:",$releaseId)) )
              return
                if (count($themeRestrictions)=1) then
                    $themeRestrictions
                else if (count($themeRestrictions)>1) then
                    <owl:Class>
                        <owl:unionOf rdf:parseType="Collection">
                            {$themeRestrictions}                           
                        </owl:unionOf>
                    </owl:Class>
                else ()
            }
:)