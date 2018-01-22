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
  deselect()
  currentMode = mode
  switch mode
    when 'draw'
      drawMode()
    when 'drag'
      dragMode()

nurbSelected = null
deselect = ->
  nurbSelected = null
  svg.select '.selected'
  .removeClass 'selected'
  elt.disabled = true for elt in document.querySelectorAll '.needSelected'
nurbSelect = (nurb) ->
  deselect()
  nurbSelected = nurb
  setWeight nurb.w
  elt.disabled = false for elt in document.querySelectorAll '.needSelected'

currentWeight = 1
getWeight = -> currentWeight
setWeight = (weight) ->
  currentWeight = weight
  weightText.value = weight
  weightRange.value = weight
  for nurb in [nurbDraw, nurbSelected]
    if nurb?
      nurb.w = weight
      nurb.update()

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
  nurbDraw = new NurbCurve w: getWeight()
  nurbDraw.render svg
  nurbDraw.a = [0,0]
  nurbDraw.select()

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
    .click =>
      @select() if getMode() == 'drag'
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
    @svgFoci = for i in [0, 1]
      do (i) =>
        circle = svg.circle()
        .hide()
        .radius controlRadius
        .addClass 'focus'
    @update()
  select: ->
    nurbSelect @
    for component in [@svgPath].concat @svgControls
      component.addClass 'selected'
      component.front()
  update: ->
    for p, i in [@a, @b, @c]
      if p?
        @svgControls[i].center p...
        .show()
    if @b?
      @svgPath.plot (@sample (t/100) for t in [0..100])
      @svgPathExtend1.plot (@sample (-10*t/200) for t in [0..200])
      @svgPathExtend2.plot (@sample (1+10*t/200) for t in [0..200])
    if @c?
      if @w != 1
        c = [(@a[0] - 2*@w*@w*@b[0] + @c[0])/(2*(1 - @w*@w))
             (@a[1] - 2*@w*@w*@b[1] + @c[1])/(2*(1 - @w*@w))]
        p = (@a[0] - @c[0] + @a[1] - @c[1])*(@a[0] - @c[0] - @a[1] + @c[1])/4 + @w*@w*((@a[1] - @b[1])*(@b[1] - @c[1]) - (@a[0] - @b[0])*(@b[0] - @c[0]))
        q = (@a[0] - @c[0])*(@a[1] - @c[1])/2 + @w*@w*(@c[0]*(@a[1] - @b[1]) - @a[0]*(@b[1] - @c[1]) - @b[0]*(@a[1] - 2*@b[1] + @c[1]))
        r = Math.sqrt(p + Math.sqrt(p*p + q*q))
        s = Math.sqrt(-p + Math.sqrt(p*p + q*q))
        s *= -1 if q < 0
        denom = Math.sqrt(2)*(1 - @w*@w)
        d = [r/denom, s/denom]
        for sign, i in [+1, -1]
          #console.log c[0] + sign*d[0], c[1] + sign*d[1], denom, r, p, q
          @svgFoci[i].show().center c[0] + sign*d[0], c[1] + sign*d[1]
      else
        focus.hide() for focus in @svgFoci
  remove: ->
    @svgPath.remove()
    @svgPathExtend1.remove()
    @svgPathExtend2.remove()
    control.remove() for control in @svgControls
  coords: ->
    [@a, @b, @c]
  weights: ->
    [1, @w, 1]

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
  setMode getMode()  ## initialize mode

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

  ## Weights
  document.getElementById('weightRange').addEventListener 'input', ->
    setWeight document.getElementById('weightRange').value
  document.getElementById('weightText').addEventListener 'change', ->
    sqrt = Math.sqrt
    rt = Math.sqrt
    log = Math.log
    sin = Math.sin
    cos = Math.cos
    tan = Math.tan
    asin = Math.asin
    acos = Math.acos
    atan = Math.atan
    weight = eval document.getElementById('weightText').value
    if weight != NaN
      setWeight weight

  ## Operations
  document.getElementById('delete').addEventListener 'click', ->
    selected = svg.select '.selected'
    if nurbDraw? and selected.has nurbDraw
      nurbDraw.remove()
      drawNewNurb()
    else
      nurbs =
        for nurb in nurbs
          if selected.has nurb.svgPath
            nurb.remove()
            continue
          else
            nurb

  ## Settings
  document.getElementById('extended').addEventListener 'change', ->
    if document.getElementById('extended').checked
      svg.removeClass 'hideExtended'
    else
      svg.addClass 'hideExtended'
  document.getElementById('controls').addEventListener 'change', ->
    if document.getElementById('controls').checked
      svg.removeClass 'hideControls'
    else
      svg.addClass 'hideControls'

  ## Save/load
  document.getElementById('download').addEventListener 'click', ->
    fold = JSON.stringify
      file_spec: 2
      file_creator: 'CurvedCreaseEdit'
      curves_coords:
        for nurb in nurbs
          nurb.coords()
      curves_weights:
        for nurb in nurbs
          nurb.weights()
    blob = new Blob [fold], type: 'application/json'
    document.getElementById('downloadLink').href = URL.createObjectURL blob
    document.getElementById('downloadLink').click()

  ## Render canvas
  grid = new Grid svg
  grid.draw -5, -5, 5, 5
  for nurb in nurbs
    nurb.render svg
  #svg.viewbox svg.bbox()
  svg.viewbox -5-margin, -5-margin, 10+2*margin, 10+2*margin

window.onload = gui
