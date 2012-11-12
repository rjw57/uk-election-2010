createColourSwatch = (t, r4) ->
  $('canvas#colour-swatch').each (idx, elem) =>
    ctx = elem.getContext('2d')
    imageData = ctx.createImageData(ctx.canvas.width, ctx.canvas.height)

    for row in [0...imageData.height]
      for col in [0...imageData.width]
        idx = (row*imageData.width + col)*4

        s = 1
        nx = s*col/imageData.width
        ny = s*row/imageData.height
        l1 = Math.max(0, 1-Math.sqrt(nx*nx + ny*ny))
        l2 = Math.max(0, 1-Math.sqrt((s-nx)*(s-nx) + ny*ny))
        l3 = Math.max(0, 1-Math.sqrt((s-nx)*(s-nx) + (s-ny)*(s-ny)))
        l4 = Math.max(0, 1-Math.sqrt(nx*nx + (s-ny)*(s-ny)))

        n = l1+l2+l3+l4
        l1 /= n
        l2 /= n
        l3 /= n

        r = l1*t[0][0] + l2*t[1][0] + l3*t[2][0] + r4[0]
        g = l1*t[0][1] + l2*t[1][1] + l3*t[2][1] + r4[1]
        b = l1*t[0][2] + l2*t[1][2] + l3*t[2][2] + r4[2]

        imageData.data[idx+0] = r
        imageData.data[idx+1] = g
        imageData.data[idx+2] = b
        imageData.data[idx+3] = 255
    
    ctx.putImageData imageData, 0, 0

$ ->
  @map = new OpenLayers.Map 'constituency-map'

  @map.addLayer new OpenLayers.Layer.OSM
  @map.zoomToMaxExtent()

  # Colours
  r1 = [192,   0,   0]  # red
  r2 = [255, 210,   0]  # yellow
  r3 = [  0,   0, 192]  # blue
  r4 = [  0, 192,   0]  # green

  t = [[r1[0]-r4[0], r1[1]-r4[1], r1[2]-r4[2]],
       [r2[0]-r4[0], r2[1]-r4[1], r2[2]-r4[2]],
       [r3[0]-r4[0], r3[1]-r4[1], r3[2]-r4[2]]]

  createColourSwatch t, r4

  defaultStyle = {
    fillColor: '${getFillColor}'
    strokeColor: '#000000'
    strokeWidth: 1
    strokeOpacity: 0.5
  }

  defaultContext = {
    getFillColor: (f) =>
      results = f.attributes.results || {}

      sum_vote = 0
      for own k, v of results
        sum_vote += v

      con = results.Con || 0
      lab = results.Lab || 0
      ld = results.LD || 0

      l1 = lab / sum_vote
      l2 = ld / sum_vote
      l3 = con / sum_vote

      r = l1*t[0][0] + l2*t[1][0] + l3*t[2][0] + r4[0]
      g = l1*t[0][1] + l2*t[1][1] + l3*t[2][1] + r4[1]
      b = l1*t[0][2] + l2*t[1][2] + l3*t[2][2] + r4[2]

      return jQuery.Color(r,g,b).toHexString(false)
  }

  hoverStyle = new OpenLayers.Style
    fillColor: '#A3C1AD'

  styles = {
    default: new OpenLayers.Style(defaultStyle, context: defaultContext)
    hover: hoverStyle
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

  hoverControl = new OpenLayers.Control.SelectFeature @vectorLayer,
      renderIntent: 'hover', autoActivate: true, hover: true, highlightOnly: true

  hoverFeature = null
  selectControl = new OpenLayers.Control.SelectFeature @vectorLayer,
    renderIntent: 'hover', autoActivate: true
    onSelect: (f) =>
      hoverFeature = f
      description_html = '<h4>'+f.attributes.name+'</h4>'
      description_html += '<table>'
      for own k,v of f.attributes.results
        description_html += '<tr><td align="right">' + k + ':</td><td>' + v + '</td></tr>'
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

