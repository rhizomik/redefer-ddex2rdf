declare namespace ddex=		"http://rhizomik.net/ontologies/2011/06/ddex.owl#";
declare namespace currency=	"http://rhizomik.net/ontologies/2011/06/iso4217a.owl#";
declare namespace territory="http://rhizomik.net/ontologies/2011/06/iso3166a2.owl#";
declare namespace language=	"http://rhizomik.net/ontologies/2011/06/iso639a2.owl#";
declare namespace co=		"http://rhizomik.net/ontologies/2009/09/copyrightonto.owl";
declare namespace rdf=		"http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs=		"http://www.w3.org/2000/01/rdf-schema#";
declare namespace owl=		"http://www.w3.org/2002/07/owl#";
declare namespace foaf=		"http://xmlns.com/foaf/0.1/";
declare namespace dct=		"http://purl.org/dc/terms/";

declare variable $ddex := "http://rhizomik.net/ontologies/2011/06/ddex.owl#";
declare variable $currencies := "http://rhizomik.net/ontologies/2011/06/iso4217a.owl#";
declare variable $territories := "http://rhizomik.net/ontologies/2011/06/iso3166a2.owl#";
declare variable $languages := "http://rhizomik.net/ontologies/2011/06/iso639a2.owl#";

declare variable $file external;
(: let $file := "src/main/resources/ERN-SonyDADC_Examples/1.1_G010001887844F_ERN.xml" :)

declare function local:fileURI($localId as xs:string) as xs:string
{
	let $fileURI := concat("file:///",$file,"#",$localId)
	return ($fileURI)
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
        else local:fileURI($localId)
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
        else local:fileURI($localId)
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

for $resource at $i in doc($file)//ResourceList/*
    let $resourceId := local:getResourceURI(data($resource/ResourceReference))
    return
    <rdf:Description rdf:about="{$resourceId}">
        { for $type in $resource/(SoundRecordingType|MidiType|VideoType|ImageType|TextType) return <rdf:type rdf:resource="{concat($ddex,$type)}"/> }
        { for $title in $resource/(ReferenceTitle|Title)/TitleText return <dct:title>{data($title)}</dct:title> }
        { for $altTitle in $resource/(ReferenceTitle|Title)/SubTitle return <dct:alternative>{data($altTitle)}</dct:alternative> }
        { for $duration in $resource/Duration return <dct:extent>{data($duration)}</dct:extent> }
    </rdf:Description>,

for $release at $i in doc($file)//ReleaseList/Release
    let $releaseId := local:getReleaseURI(data($release/ReleaseReference))
    return
    <rdf:Description rdf:about="{$releaseId}">
        { for $type in $release/ReleaseType return <rdf:type rdf:resource="{concat($ddex,$type)}"/> }
        { for $title in $release/ReferenceTitle/TitleText return <dct:title>{data($title)}</dct:title> }
        { for $altTitle in $release/ReferenceTitle/SubTitle return <dct:alternative>{data($altTitle)}</dct:alternative> }
        { for $duration in $release/Duration return <dct:extent>{data($duration)}</dct:extent> }
        { for $copyright in $release/(CLine|PLine)/(CLineText|PLineText) return <dct:copyright>{data($copyright)}</dct:copyright> }
        { for $resource in $release/ReleaseResourceReferenceList/ReleaseResourceReference return <dct:hasPart rdf:resource="{local:getResourceURI(data($resource))}"/> }
    </rdf:Description>,

for $deal at $i in doc($file)//DealTerms
    let $dealId := local:fileURI(concat("DEAL",$i))
    return
<cro:Agree rdf:about="{concat("file:///",$file)}">
    { if ($deal/../../EffectiveDate) then <cro:pointInTime>{data($deal/../../EffectiveDate)}</cro:pointInTime> else () }
    <cro:theme>
    <rdf:Description rdf:about="{$dealId}">
        { for $use in $deal/Usage/UseType return <rdf:type rdf:resource="{concat($ddex,$use)}"/> }
        { for $releaseRef in $deal/../../DealReleaseReference
            return (<cro:theme rdf:resource="{local:getReleaseURI($releaseRef)}"/>,
                    for $resourceId in local:getReleaseResourcesURIs($releaseRef) return <cro:theme rdf:resource="{$resourceId}"/>) }
        { for $releaseId in $deal/../../ReleaseId/GRid return <cro:theme rdf:resource="{concat("urn:grid:",$releaseId)}"/> }
        { for $distributor in $deal/DistributionChannel return 
            <cro:agent>
                <rdf:Description>
                    { if ($distributor/PartyId) then <dct:identifier>{data($distributor/PartyId)}</dct:identifier> else () }
                    { if ($distributor/PartyName/FullName) then <foaf:name>{data($distributor/PartyName/FullName)}</foaf:name> else () }
                </rdf:Description>
            </cro:agent> }
        { for $commercialModel in $deal/CommercialModelType return <cro:aim rdf:resource="{concat($ddex,$commercialModel)}"/> }
        { for $userInterface in $deal/Usage/UserInterfaceType return <cro:instrument rdf:resource="{concat($ddex,$userInterface)}"/> }
        { for $distributionChannel in $deal/Usage/DistributionChannelType return <cro:medium rdf:resource="{concat($ddex,$distributionChannel)}"/> }
        { for $territory in $deal/TerritoryCode return <cro:location rdf:resource="{concat($territories,$territory)}"/> }
        { for $period in $deal/ValidityPeriod return (
            if ($period/StartDate) then <cro:start>{data($period/StartDate)}</cro:start> else (),
            if ($period/EndDate) then <cro:completion>{data($period/EndDate)}</cro:completion> else () ) }
        { for $priceInfo in $deal/PriceInformation/* return 
            <cro:condition>
                <rdf:Description>
                    <rdf:type rdf:resource="{concat($ddex,node-name($priceInfo))}"/>
                    <rdf:value>{data($priceInfo)}</rdf:value>
                    { if ($priceInfo/@CurrencyCode) then <cro:currency rdf:resource="{concat($currencies,$priceInfo/@CurrencyCode)}"/> else () }
                </rdf:Description>
            </cro:condition> }
    </rdf:Description>
    </cro:theme>
</cro:Agree>

    (: TODO: deal with CatalogNumbers :)
    (: TODO: DealTechnicalResourceDetailsReferenceList, e.g. in SonyDADC DDEX example 1.4 :)
    (: TODO: if multiple ValidityPeriod, model as different actions :)
    (: TODO: consider specifics for PriceRangeType and PriceType :)      
    (: TODO: deal with ResourceUsages :)
    (: TODO: isExclusive, AllDealsCancelled (rare), TakeDown (specific right or just everything down?), ExcludedTerritoryCode (not common) :)
    