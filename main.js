(function() {
  var barycentricCoordToColour, createColourSwatch, r1, r2, r3, r4, resultsToBarycentric, t,
    __hasProp = {}.hasOwnProperty;

  r1 = [146, 0, 13];

  r2 = [253, 187, 48];

  r3 = [0, 135, 220];

  r4 = [0, 146, 65];

  t = [[r1[0] - r4[0], r1[1] - r4[1], r1[2] - r4[2]], [r2[0] - r4[0], r2[1] - r4[1], r2[2] - r4[2]], [r3[0] - r4[0], r3[1] - r4[1], r3[2] - r4[2]]];

  barycentricCoordToColour = function(l1, l2, l3) {
    var b, g, r;
    r = l1 * t[0][0] + l2 * t[1][0] + l3 * t[2][0] + r4[0];
    g = l1 * t[0][1] + l2 * t[1][1] + l3 * t[2][1] + r4[1];
    b = l1 * t[0][2] + l2 * t[1][2] + l3 * t[2][2] + r4[2];
    return [r, g, b];
  };

  createColourSwatch = function(elems, ordering) {
    var _this = this;
    if (ordering == null) {
      ordering = [0, 1, 3, 2];
    }
    return elems.each(function(idx, elem) {
      var b, bl, br, col, ctx, g, imageData, l, l1, l2, l3, l4, n, nx, ny, r, row, s, tl, tr, _i, _j, _ref, _ref1, _ref2;
      ctx = elem.getContext('2d');
      imageData = ctx.createImageData(ctx.canvas.width, ctx.canvas.height);
      for (row = _i = 0, _ref = imageData.height; 0 <= _ref ? _i < _ref : _i > _ref; row = 0 <= _ref ? ++_i : --_i) {
        for (col = _j = 0, _ref1 = imageData.width; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; col = 0 <= _ref1 ? ++_j : --_j) {
          idx = (row * imageData.width + col) * 4;
          s = 1;
          nx = s * col / imageData.width;
          ny = s * row / imageData.height;
          tl = Math.max(0, 1 - Math.sqrt(nx * nx + ny * ny));
          tr = Math.max(0, 1 - Math.sqrt((s - nx) * (s - nx) + ny * ny));
          br = Math.max(0, 1 - Math.sqrt((s - nx) * (s - nx) + (s - ny) * (s - ny)));
          bl = Math.max(0, 1 - Math.sqrt(nx * nx + (s - ny) * (s - ny)));
          l = [0, 0, 0, 0];
          l[ordering[0]] = tl;
          l[ordering[1]] = tr;
          l[ordering[2]] = bl;
          l[ordering[3]] = br;
          l1 = l[0];
          l2 = l[1];
          l3 = l[2];
          l4 = l[3];
          n = l1 + l2 + l3 + l4;
          l1 /= n;
          l2 /= n;
          l3 /= n;
          _ref2 = barycentricCoordToColour(l1, l2, l3), r = _ref2[0], g = _ref2[1], b = _ref2[2];
          imageData.data[idx + 0] = r;
          imageData.data[idx + 1] = g;
          imageData.data[idx + 2] = b;
          imageData.data[idx + 3] = 255;
        }
      }
      return ctx.putImageData(imageData, 0, 0);
    });
  };

  resultsToBarycentric = function(results, normalise) {
    var k, l1, l2, l3, l4, s, v;
    if (normalise == null) {
      normalise = true;
    }
    l1 = l2 = l3 = l4 = 0;
    for (k in results) {
      if (!__hasProp.call(results, k)) continue;
      v = results[k];
      switch (k) {
        case 'Lab':
          l1 += v;
          break;
        case 'LD':
          l2 += v;
          break;
        case 'Con':
          l3 += v;
          break;
        default:
          l4 += v;
      }
    }
    if (normalise) {
      s = l1 + l2 + l3 + l4;
      l1 /= s;
      l2 /= s;
      l3 /= s;
      l4 /= s;
    }
    return [l1, l2, l3, l4];
  };

  $(function() {
    var defaultContext, defaultStyle, hoverControl, hoverFeature, hoverStyle, selectControl, selectStyle, styles,
      _this = this;
    this.map = new OpenLayers.Map('constituency-map');
    this.map.addLayer(new OpenLayers.Layer.OSM);
    this.map.zoomToMaxExtent();
    createColourSwatch($('canvas#colour-swatch-1'), [0, 1, 3, 2]);
    createColourSwatch($('canvas#colour-swatch-2'), [0, 1, 2, 3]);
    defaultStyle = {
      fillColor: '${getFillColor}',
      strokeColor: '#000000',
      strokeWidth: 1,
      strokeOpacity: 0.5
    };
    defaultContext = {
      getFillColor: function(f) {
        var b, g, l1, l2, l3, l4, r, results, _ref, _ref1;
        results = f.attributes.results || {};
        _ref = resultsToBarycentric(results), l1 = _ref[0], l2 = _ref[1], l3 = _ref[2], l4 = _ref[3];
        _ref1 = barycentricCoordToColour(l1, l2, l3), r = _ref1[0], g = _ref1[1], b = _ref1[2];
        return jQuery.Color(r, g, b).toHexString(false);
      }
    };
    hoverStyle = new OpenLayers.Style({
      fillColor: '#A3C1AD'
    });
    selectStyle = new OpenLayers.Style({
      strokeColor: '#0000ee',
      strokeWidth: 3
    });
    styles = {
      "default": new OpenLayers.Style(defaultStyle, {
        context: defaultContext
      }),
      hover: hoverStyle,
      select: selectStyle
    };
    this.vectorLayer = new OpenLayers.Layer.Vector('Constituencies', {
      styleMap: new OpenLayers.StyleMap(styles, {
        extendDefault: true
      }),
      projection: 'EPSG:4326',
      strategies: [new OpenLayers.Strategy.Fixed],
      displayInLayerSwitcher: false,
      attribution: 'Contains Ordnance Survey data &copy; Crown copyright and database right 2011.',
      protocol: new OpenLayers.Protocol.HTTP({
        url: 'constituencies_with_results.json',
        format: new OpenLayers.Format.GeoJSON
      })
    });
    this.vectorLayer.events.register('loadend', null, function() {
      var b, f, g, l1, l1_, l2, l2_, l3, l3_, l4, l4_, r, results, s, _i, _len, _ref, _ref1, _ref2;
      _this.map.zoomToExtent(_this.vectorLayer.getDataExtent());
      l1 = l2 = l3 = l4 = 0;
      _ref = _this.vectorLayer.features;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        f = _ref[_i];
        results = f.attributes.results || {};
        _ref1 = resultsToBarycentric(results, false), l1_ = _ref1[0], l2_ = _ref1[1], l3_ = _ref1[2], l4_ = _ref1[3];
        l1 += l1_;
        l2 += l2_;
        l3 += l3_;
        l4 += l4_;
      }
      s = l1 + l2 + l3 + l4;
      $('#popular-vote-caption').html('<table>' + '<tr><td align="right">Con:</td><td>' + l3 + '</td><td>(' + Math.round(100 * l3 / s) + '%)</td></tr>' + '<tr><td align="right">Lab:</td><td>' + l1 + '</td><td>(' + Math.round(100 * l1 / s) + '%)</td></tr>' + '<tr><td align="right">LD:</td><td>' + l2 + '</td><td>(' + Math.round(100 * l2 / s) + '%)</td></tr>' + '<tr><td align="right">Oth:</td><td>' + l4 + '</td><td>(' + Math.round(100 * l4 / s) + '%)</td></tr>' + '</table>');
      l1 /= s;
      l2 /= s;
      l3 /= s;
      l4 /= s;
      _ref2 = barycentricCoordToColour(l1, l2, l3), r = _ref2[0], g = _ref2[1], b = _ref2[2];
      return $('#popular-vote').css('background-color', jQuery.Color(r, g, b).toHexString(false));
    });
    hoverControl = new OpenLayers.Control.SelectFeature(this.vectorLayer, {
      renderIntent: 'hover',
      autoActivate: true,
      hover: true,
      highlightOnly: true
    });
    hoverFeature = null;
    selectControl = new OpenLayers.Control.SelectFeature(this.vectorLayer, {
      autoActivate: true,
      onSelect: function(f) {
        var description_html, i, k, popup, r, rows, sum, v, _ref;
        hoverFeature = f;
        description_html = '<h4>' + f.attributes.name + '</h4>';
        description_html += '<table>';
        rows = [];
        sum = 0;
        _ref = f.attributes.results;
        for (k in _ref) {
          if (!__hasProp.call(_ref, k)) continue;
          v = _ref[k];
          rows.push([k, v]);
          sum += v;
        }
        rows.sort(function(a, b) {
          return b[1] - a[1];
        });
        for (i in rows) {
          r = rows[i];
          k = r[0];
          v = r[1];
          description_html += '<tr><td align="right">' + k + ':</td><td>' + v + '</td><td>(' + Math.round(100 * v / sum) + '%)</td></tr>';
        }
        description_html += '</table>';
        popup = new OpenLayers.Popup.FramedCloud('hover-popup', f.geometry.getBounds().getCenterLonLat(), null, description_html, null, true, function() {
          return selectControl.unselect(hoverFeature);
        });
        f.popup = popup;
        return _this.map.addPopup(popup);
      },
      onUnselect: function(f) {
        _this.map.removePopup(f.popup);
        f.popup.destroy();
        f.popup = null;
        return hoverFeature = null;
      }
    });
    selectControl.handlers.feature.stopDown = false;
    hoverControl.handlers.feature.stopDown = false;
    this.map.addControl(hoverControl);
    this.map.addControl(selectControl);
    return this.map.addLayer(this.vectorLayer);
  });

}).call(this);
