Backbone = require 'backbone'
_ = require 'underscore'

module.exports = class MonocleView extends Backbone.View

  initialize: (options) ->
    { @artwork } = options
    @monocleSize = parseInt(@$('.monocle-zoom').css('width').replace 'px', '') / 2
    @preCalc()
    @removeAltTag()
    @bindMonocles()
    @hideMonocle()

  removeAltTag: ->
    @$('img').attr('title', '')

  # Calculate and cache some numbers
  preCalc: ->
    @top = @$el.offset().top
    @left = @$el.offset().left
    @imgTop = @$('img').offset().top
    @imgLeft = @$('img').offset().left
    @imgWidth = @$('img').width()
    @imgHeight = @$('img').height()
    @origHeight = @artwork.defaultImage().get('original_height')
    @origWidth = @artwork.defaultImage().get('original_width')
    aspectRatio = @origWidth / @origHeight
    if aspectRatio > 1
      @largerWidth = 1024
      @largerHeight = 1024 / aspectRatio
    else if aspectRatio < 1
      @largerHeight = 1024
      @largerWidth = 1024 * aspectRatio
    else
      @largerHeight = 1024
      @largerWidth = 1024

  events:
    'mouseleave img': 'hideMonocle'
    'mouseenter img': 'showMonocle'

  showMonocle: ->
    @$('.monocle-zoom').show()

  hideMonocle: ->
    @$('.monocle-zoom').hide()

  bindMonocles: ->
    @$('img').mousemove (event) =>
      @positionAndRecalc()

  positionAndRecalc: ->
    @currentLeft = event.pageX
    @currentTop = event.pageY
    left = @currentLeft - @left - @monocleSize
    top = @currentTop - @top - @monocleSize
    @$('.monocle-zoom').css
      'left': left
      'top': top
    @recalcBackground()

  recalcBackground: ->
    distToTop = @currentTop - @imgTop
    distFromLeft = @currentLeft - @imgLeft
    pctOffsetTop = distToTop / @imgHeight
    pctOffsetLeft = distFromLeft / @imgWidth
    bgLeft = -pctOffsetLeft * @largerWidth
    bgHeight = -pctOffsetTop * @largerHeight
    bgLeft += @monocleSize
    bgHeight += @monocleSize
    @$('.monocle-zoom').css('background-position', "#{bgLeft}px #{bgHeight}px")
