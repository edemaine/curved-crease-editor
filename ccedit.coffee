svg = grid = null
controlRadius = 0.2
margin = 0.25

getMode = ->
  document.querySelector('.mode.selected').getAttribute 'id'

class NurbCurve
  constructor: (opts = {}) ->
    ## `opt` should have keys among ['a', 'b', 'c', 'w']
    @w = 1  ## default
    @[key] = value for key, value of opts
  sample: (t) ->
    c1 = (1-t)*(1-t)
    c2 = 2*@w*t*(1-t)
    c3 = t*t
    denom = c1 + c2 + c3
    (c1*@a[d] + c2*@b[d] + c3*@c[d])/denom for d in [0...@a.length]
  render: (svg) ->
    @svgPath = svg.polyline()
    @svgControls = for p, i in [@a, @b, @c]
      do (p) =>
        circle = svg.circle()
        .radius controlRadius
        .addClass 'control'
        .mousedown =>
          return unless getMode() == 'drag'
          circle.addClass 'dragging'
          svg.mousemove (e) =>
            point = svg.point e.clientX, e.clientY
            p[0] = point.x
            p[1] = point.y
            for d in [0...2]
              p[d] = Math.round p[d]
            @update()
    @update()
  update: ->
    @svgPath.plot (@sample (t/100) for t in [0..100])
    for p, i in [@a, @b, @c]
      @svgControls[i].center p...

nurbs = [
  new NurbCurve
    a: [0,0]
    b: [0,2]
    w: 1
    c: [2,4]
  new NurbCurve
    a: [1,0]
    b: [1,1]
    w: 1/Math.sqrt 2
    c: [2,1]
]

class Grid
  constructor: (@svg) ->
    @group = @svg.group()
  draw: (@xmin, @ymin, @xmax, @ymax) ->
    @group.clear()
    for x in [@xmin..@xmax]
      @group.line x, @ymin, x, @ymax
      .addClass 'grid'
    for y in [@ymin..@ymax]
      @group.line @xmin, y, @xmax, y
      .addClass 'grid'

dragStop = ->
  svg.off 'mousemove'
  svg.select '.dragging'
  .removeClass 'dragging'

gui = ->
  svg = SVG 'canvas'

  ## Support dragging
  svg.on 'dragstart', (e) ->
    e.preventDefault()
    e.stopPropagation()
  svg.on 'selectstart', (e) ->
    e.preventDefault()
    e.stopPropagation()
  ## Stop dragging
  svg.on 'mouseup', dragStop
  svg.on 'mouseleave', dragStop

  ## Mode selection
  for mode in document.getElementsByClassName 'mode'
    mode.addEventListener 'click', (e) ->
      for other in document.getElementsByClassName 'selected'
        other.classList.remove 'selected'
      e.target.classList.add 'selected'

  ## Draw mode
  #svg.click 

  ## Render canvas
  grid = new Grid svg
  grid.draw -5, -5, 5, 5
  for nurb in nurbs
    nurb.render svg
  #svg.viewbox svg.bbox()
  svg.viewbox -5-margin, -5-margin, 10+2*margin, 10+2*margin

window.onload = gui
