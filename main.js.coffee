# Colours
r1 = [146,  0,   13]  # red = Lab
r2 = [253, 187,  48]  # yellow = LD
r3 = [  0, 135, 220]  # blue = Con
r4 = [  0, 146,  65]  # Oth

t = [[r1[0]-r4[0], r1[1]-r4[1], r1[2]-r4[2]],
     [r2[0]-r4[0], r2[1]-r4[1], r2[2]-r4[2]],
     [r3[0]-r4[0], r3[1]-r4[1], r3[2]-r4[2]]]

barycentricCoordToColour = (l1, l2, l3) ->
  r = l1*t[0][0] + l2*t[1][0] + l3*t[2][0] + r4[0]
  g = l1*t[0][1] + l2*t[1][1] + l3*t[2][1] + r4[1]
  b = l1*t[0][2] + l2*t[1][2] + l3*t[2][2] + r4[2]
  [r,g,b]

# ordering give which barycentric co-ord corresponds to tl, tr, bl, br
createColourSwatch = (elems, ordering = [0,1,3,2]) ->
  elems.each (idx, elem) =>
    ctx = elem.getContext('2d')
    imageData = ctx.createImageData(ctx.canvas.width, ctx.canvas.height)

    for row in [0...imageData.height]
      for col in [0...imageData.width]
        idx = (row*imageData.width + col)*4

        s = 1
        nx = s*col/imageData.width
        ny = s*row/imageData.height

        tl = Math.max(0, 1-Math.sqrt(nx*nx + ny*ny))
        tr = Math.max(0, 1-Math.sqrt((s-nx)*(s-nx) + ny*ny))
        br = Math.max(0, 1-Math.sqrt((s-nx)*(s-nx) + (s-ny)*(s-ny)))
        bl = Math.max(0, 1-Math.sqrt(nx*nx + (s-ny)*(s-ny)))

        l = [0,0,0,0]
        l[ordering[0]] = tl
        l[ordering[1]] = tr
        l[ordering[2]] = bl
        l[ordering[3]] = br

        l1 = l[0]
        l2 = l[1]
        l3 = l[2]
        l4 = l[3]

        n = l1+l2+l3+l4
        l1 /= n
        l2 /= n
        l3 /= n

        [r,g,b] = barycentricCoordToColour l1, l2, l3

        imageData.data[idx+0] = r
        imageData.data[idx+1] = g
        imageData.data[idx+2] = b
        imageData.data[idx+3] = 255
    
    ctx.putImageData imageData, 0, 0

# Return the barycentric (un-normalised or normalised) co-ordinates from a set of results
resultsToBarycentric = (results, normalise=true) ->
  l1 = l2 = l3 = l4 = 0

  for own k,v of results
    switch k
      when 'Lab' then l1 += v
      when 'LD'  then l2 += v
      when 'Con' then l3 += v
      else            l4 += v

  if normalise
    s = l1+l2+l3+l4
    l1 /= s
    l2 /= s
    l3 /= s
    l4 /= s

  return [l1, l2, l3, l4]

$ ->
  @map = new OpenLayers.Map 'constituency-map'

  @map.addLayer new OpenLayers.Layer.OSM
  @map.zoomToMaxExtent()

  createColourSwatch $('canvas#colour-swatch-1'), [0,1,3,2]
  createColourSwatch $('canvas#colour-swatch-2'), [0,1,2,3]

  defaultStyle = {
    fillColor: '${getFillColor}'
    strokeColor: '#000000'
    strokeWidth: 1
    strokeOpacity: 0.5
  }

  defaultContext = {
    getFillColor: (f) =>
      results = f.attributes.results || {}
      [l1, l2, l3, l4] = resultsToBarycentric results
      [r, g, b] = barycentricCoordToColour l1, l2, l3
      return jQuery.Color(r,g,b).toHexString(false)
  }

  hoverStyle = new OpenLayers.Style
    fillColor: '#A3C1AD'

  selectStyle = new OpenLayers.Style
    strokeColor: '#0000ee'
    strokeWidth: 3

  styles = {
    default: new OpenLayers.Style(defaultStyle, context: defaultContext)
    hover: hoverStyle
    select: selectStyle
  }

  # Create the vector overlay layer
  @vectorLayer = new OpenLayers.Layer.Vector 'Constituencies',
    styleMap: new OpenLayers.StyleMap(styles, extendDefault: true)
    projection: 'EPSG:4326'
    strategies: [new OpenLayers.Strategy.Fixed]
    displayInLayerSwitcher: false
    attribution: 'Contains Ordnance Survey data &copy; Crown copyright and database right 2011.'
    protocol: new OpenLayers.Protocol.HTTP( url: 'constituencies_with_results.json', format: new OpenLayers.Format.GeoJSON )

  @vectorLayer.events.register 'loadend', null, () =>
    @map.zoomToExtent @vectorLayer.getDataExtent()

    # Calculate overall 'colour' of the country
    l1 = l2 = l3 = l4 = 0
    for f in @vectorLayer.features
      results = f.attributes.results || {}
      [l1_, l2_, l3_, l4_] = resultsToBarycentric results, false
      l1 += l1_
      l2 += l2_
      l3 += l3_
      l4 += l4_
    s = l1+l2+l3+l4
    $('#popular-vote-caption').html('<table>' +
      '<tr><td align="right">Con:</td><td>' + l3 + '</td><td>(' + Math.round(100*l3/s) + '%)</td></tr>' +
      '<tr><td align="right">Lab:</td><td>' + l1 + '</td><td>(' + Math.round(100*l1/s) + '%)</td></tr>' +
      '<tr><td align="right">LD:</td><td>' + l2 + '</td><td>(' + Math.round(100*l2/s) + '%)</td></tr>' +
      '<tr><td align="right">Oth:</td><td>' + l4 + '</td><td>(' + Math.round(100*l4/s) + '%)</td></tr>' +
      '</table>')
    l1 /= s
    l2 /= s
    l3 /= s
    l4 /= s
    [r, g, b] = barycentricCoordToColour l1, l2, l3
    $('#popular-vote').css('background-color', jQuery.Color(r,g,b).toHexString(false))

  hoverControl = new OpenLayers.Control.SelectFeature @vectorLayer,
      renderIntent: 'hover', autoActivate: true, hover: true, highlightOnly: true

  hoverFeature = null
  selectControl = new OpenLayers.Control.SelectFeature @vectorLayer,
    autoActivate: true
    onSelect: (f) =>
      hoverFeature = f
      description_html = '<h4>'+f.attributes.name+'</h4>'
      description_html += '<table>'

      rows = []
      sum = 0
      for own k,v of f.attributes.results
        rows.push([k,v])
        sum += v
      rows.sort((a,b) -> b[1]-a[1])
      for i,r of rows
        k = r[0]
        v = r[1]
        description_html += '<tr><td align="right">' + k + ':</td><td>' + v + '</td><td>(' + Math.round(100*v/sum) + '%)</td></tr>'

      description_html += '</table>'
      popup = new OpenLayers.Popup.FramedCloud 'hover-popup',
        f.geometry.getBounds().getCenterLonLat(),
        null, description_html,
        null, true,
        () => selectControl.unselect(hoverFeature)
      f.popup = popup
      @map.addPopup(popup)
    onUnselect: (f) =>
      @map.removePopup(f.popup)
      f.popup.destroy()
      f.popup = null
      hoverFeature = null

  selectControl.handlers.feature.stopDown = false
  hoverControl.handlers.feature.stopDown = false

  @map.addControl(hoverControl)
  @map.addControl(selectControl)

  @map.addLayer @vectorLayer

