svg = grid = null
controlRadius = 0.2
margin = 0.25

round = Math.round

currentMode = 'drag'
getMode = -> currentMode
  #document.querySelector('.mode.selected').getAttribute 'data-mode'
setMode = (mode) ->
  drawStop()
  dragStop()
  currentMode = mode
  switch mode
    when 'draw'
      drawMode()
    when 'drag'
      dragMode()

### DRAG MODE ###

dragMode = ->
  svg.on 'mouseup', dragEnd
  svg.on 'mouseleave', dragEnd

dragEnd = ->
  svg.off 'mousemove'
  svg.select '.dragging'
  .removeClass 'dragging'

dragStop = ->
  svg.off 'mouseup'
  svg.off 'mouseleave'

### DRAW MODE ###

nurbDraw = null

drawNewNurb = ->
  nurbDraw = new NurbCurve
  nurbDraw.render svg
  nurbDraw.a = [0,0]

drawMode = ->
  drawNewNurb()
  svg.mousemove mousemove = (e) ->
    return unless getMode() == 'draw'
    point = svg.point e.clientX, e.clientY
    control = nurbDraw.c ? nurbDraw.b ? nurbDraw.a
    control[0] = round point.x
    control[1] = round point.y
    nurbDraw.update()
  svg.mousedown (e) ->
    mousemove e
    ## Advance to next point
    if not nurbDraw.b?
      nurbDraw.b = [0,0]
    else if not nurbDraw.c?
      nurbDraw.c = [0,0]
    else
      nurbs.push nurbDraw
      drawNewNurb()

drawStop = ->
  if nurbDraw?
    nurbDraw.remove()
    nurbDraw = null
  svg.off 'mousemove'
  svg.off 'mousedown'

### NURBS ###

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
    (c1*@a[d] + c2*@b[d] + c3*(@c ? @b)[d])/denom for d in [0...@a.length]
  render: (svg) ->
    @svgPathExtend1 = svg.polyline()
    .addClass 'extended'
    @svgPathExtend2 = svg.polyline()
    .addClass 'extended'
    @svgPath = svg.polyline()
    @svgControls = for p, i in ['a', 'b', 'c']
      do (p) =>
        circle = svg.circle()
        .hide()
        .radius controlRadius
        .addClass 'control'
        .mousedown =>
          return unless getMode() == 'drag'
          circle.addClass 'dragging'
          svg.mousemove (e) =>
            point = svg.point e.clientX, e.clientY
            @[p][0] = round point.x
            @[p][1] = round point.y
            @update()
    @update()
  update: ->
    for p, i in [@a, @b, @c]
      if p?
        @svgControls[i].center p...
        .show()
    if @b?
      @svgPath.plot (@sample (t/100) for t in [0..100])
      @svgPathExtend1.plot (@sample (-10*t/200) for t in [0..200])
      @svgPathExtend2.plot (@sample (1+10*t/200) for t in [0..200])
  remove: ->
    @svgPath.remove()
    control.remove() for control in @svgControls

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

### GRID ###

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

### GUI ###

gui = ->
  svg = SVG 'canvas'

  ## Support dragging
  svg.on 'dragstart', (e) ->
    e.preventDefault()
    e.stopPropagation()
  svg.on 'selectstart', (e) ->
    e.preventDefault()
    e.stopPropagation()

  ## Mode selection
  for mode in document.getElementsByClassName 'mode'
    mode.addEventListener 'click', (e) ->
      document.querySelector('.mode.selected').classList.remove 'selected'
      e.target.classList.add 'selected'
      setMode e.target.getAttribute 'data-mode'

  ## Render canvas
  grid = new Grid svg
  grid.draw -5, -5, 5, 5
  for nurb in nurbs
    nurb.render svg
  #svg.viewbox svg.bbox()
  svg.viewbox -5-margin, -5-margin, 10+2*margin, 10+2*margin

window.onload = gui
