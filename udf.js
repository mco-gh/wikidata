 function parse(item) { 

  function wikiEncode(x) {
    return x ? (x.split(' ').join('_')) : null;
  }
  
  var obj = JSON.parse(item.replace(/,$/, ''));
  sitelinks =[];
  for(var i in obj.sitelinks) {
    sitelinks.push({'site':obj.sitelinks[i].site, 'title':obj.sitelinks[i].title, 'encoded':wikiEncode(obj.sitelinks[i].title)}) 
  }  
  descriptions =[];
  for(var i in obj.descriptions) {
    descriptions.push({'language':obj.descriptions[i].language, 'value':obj.descriptions[i].value}) 
  }
  labels =[];
  for(var i in obj.labels) {
    labels.push({'language':obj.labels[i].language, 'value':obj.labels[i].value}) 
  }
  aliases =[];
  for(var i in obj.aliases) {
    for(var j in obj.aliases[i]) {
      aliases.push({'language':obj.aliases[i][j].language, 'value':obj.aliases[i][j].value}) 
    }
  }
  
  function snaks(obj, pnumber, name) {
    var snaks = []
    for(var i in obj.claims[pnumber]) {
      if (!obj.claims[pnumber][i].mainsnak.datavalue) continue;
      var claim = {}
      claim[name]=obj.claims[pnumber][i].mainsnak.datavalue.value[name.split('_').join('-')]
      snaks.push(claim) 
    }
    return snaks
  }
  function snaksValue(obj, pnumber, name) {
    var snaks = []
    for(var i in obj.claims[pnumber]) {
      if (!obj.claims[pnumber][i].mainsnak.datavalue) continue;
      var claim = {}
      claim[name]=obj.claims[pnumber][i].mainsnak.datavalue.value
      snaks.push(claim) 
    }
    return snaks
  }
  function snaksLoc(obj, pnumber) {
    var snaks = []
    for(var i in obj.claims[pnumber]) {
      if (!obj.claims[pnumber][i].mainsnak.datavalue) continue;
      var claim = {}
      claim['longitude']=obj.claims[pnumber][i].mainsnak.datavalue.value['longitude']
      claim['latitude']=obj.claims[pnumber][i].mainsnak.datavalue.value['latitude']
      snaks.push(claim) 
    }
    return snaks
  }
  function snaksNum(obj, pnumber) {
    return snaks(obj, pnumber, 'numeric_id');
  }
  
  var obj = {
    id: obj.id,
    numeric_id: parseInt(obj.id.substr(1)),
    en_wiki: obj.sitelinks ? (obj.sitelinks.enwiki ? wikiEncode(obj.sitelinks.enwiki.title) : null) : null,
    en_label: obj.labels.en ? obj.labels.en.value : null,
    en_description: obj.descriptions.en ? obj.descriptions.en.value : null,
    ja_wiki: obj.sitelinks ? (obj.sitelinks.jawiki ? wikiEncode(obj.sitelinks.jawiki.title) : null) : null,
    ja_label: obj.labels.ja ? obj.labels.ja.value : null,
    ja_description: obj.descriptions.ja ? obj.descriptions.ja.value : null,
    es_wiki: obj.sitelinks ? (obj.sitelinks.eswiki ? wikiEncode(obj.sitelinks.eswiki.title) : null) : null,
    es_label: obj.labels.es ? obj.labels.es.value : null,
    es_description: obj.descriptions.es ? obj.descriptions.es.value : null,
    de_wiki: obj.sitelinks ? (obj.sitelinks.dewiki ? wikiEncode(obj.sitelinks.dewiki.title) : null) : null,
    de_label: obj.labels.de ? obj.labels.de.value : null,
    de_description: obj.descriptions.de ? obj.descriptions.de.value : null,
    
    type: obj.type,
    labels: labels, 
    descriptions: descriptions,
    sitelinks: sitelinks,
    aliases: aliases,
    instance_of: snaksNum(obj, 'P31'),
    gender: snaksNum(obj, 'P21'),
    date_of_birth: snaks(obj, 'P569', 'time'),
    date_of_death: snaks(obj, 'P569', 'time'),
    place_of_birth: snaksNum(obj, 'P19'),
    country_of_citizenship: snaksNum(obj, 'P27'),
    country: snaksNum(obj, 'P17'),
    occupation: snaksNum(obj, 'P106'),
    instrument: snaksNum(obj, 'P1303'),
    genre: snaksNum(obj, 'P136'),
    industry: snaksNum(obj, 'P452'),
    subclass_of: snaksNum(obj, 'P279'),
    coordinate_location: snaksLoc(obj, 'P625'),
    iso_3166_alpha3: snaksValue(obj, 'P298', 'value'),
    member_of: snaksNum(obj, 'P463'),
    from_fictional_universe: snaksNum(obj, 'P1080'),
  }

  var jsonString = JSON.stringify(obj);
  return jsonString;
}
