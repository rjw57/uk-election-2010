$ ->
  @map = new OpenLayers.Map 'constituency-map'

  @map.addLayer new OpenLayers.Layer.OSM
  @map.zoomToMaxExtent()

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

      r = lab / sum_vote
      b = con / sum_vote
      y = ld / sum_vote
      g = 1 - (r + b + y)

      return jQuery.Color(255*(y+r),255*(y+g),255*b).toHexString(false)
  }

  styles = {
    default: new OpenLayers.Style(defaultStyle, context: defaultContext)
  }

  # Create the vector overlay layer
  @vectorLayer = new OpenLayers.Layer.Vector 'Constituencies',
    styleMap: new OpenLayers.StyleMap(styles, extendDefault: true)
    projection: 'EPSG:4326'
    strategies: [new OpenLayers.Strategy.Fixed]
    displayInLayerSwitcher: false
    protocol: new OpenLayers.Protocol.HTTP( url: 'constituencies_with_results.json', format: new OpenLayers.Format.GeoJSON )

  @vectorLayer.events.register 'loadend', null, () =>
    @map.zoomToExtent @vectorLayer.getDataExtent()

  @map.addLayer @vectorLayer

