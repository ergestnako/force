_               = require 'underscore'
Backbone        = require 'backbone'
{ ARTSY_URL }   = require('sharify').data
{ Markdown }    = require 'artsy-backbone-mixins'
analytics       = require '../../../lib/analytics.coffee'

Artworks            = require '../../../collections/artworks.coffee'
ArtworkColumnsView  = require '../../../components/artwork_columns/view.coffee'

template = -> require('../templates/layered-search.jade') arguments...

module.exports.Layer = class Layer extends Backbone.Model
  _.extend @prototype, Markdown

  initialize: (options = {}) ->
    @set artwork_id: @collection.artwork.id
    @set fair: @collection.fair if @get('type') is 'fair'
    @artworks = new Artworks
    @artworks.url = "#{ARTSY_URL}/api/v1/related/layer/#{@get('type')}/#{@id}/artworks?artwork[]=#{@get('artwork_id')}"

  label: ->
    return @id if (@get('type') is 'synthetic') and (@id is 'for-sale')
    @get 'type'

module.exports.Layers = class Layers extends Backbone.Collection
  url: "#{ARTSY_URL}/api/v1/related/layers"
  model: Layer

  initialize: (options) ->
    { @artwork, @fair } = options

  fetch: (options = {}) ->
    _.extend options, data: 'artwork[]': @artwork.id
    Backbone.Collection::fetch.call this, options

  # Ensure fairs are always first, followed by 'Most Similar',
  # and that 'For Sale' is always last
  sortMap: (type, id) ->
    return  -1 if (type is 'fair')
    return   0 if (type is 'synthetic') and (id is 'main')
    return   @length if (type is 'synthetic') and (id is 'for-sale')
    1

  comparator: (model) ->
    @sortMap model.get('type'), model.id

module.exports.LayeredSearchView = class LayeredSearchView extends Backbone.View
  template: template

  events:
    'click .layered-search-layer-button' : 'selectLayer'

  initialize: (options = {}) ->
    { @artwork, @fair } = options
    @setupLayers()

  setupLayers: ->
    @layers = new Layers artwork: @artwork, fair: @fair
    @layers.fetch
      success:  => @render()
      error:    => @remove()

  # Activate the clicked layer or
  # activate the first layer if called without a click event
  selectLayer: (e) ->
    id = if e
      ($target = $(e.currentTarget)).data 'id'
    else
      ($target = @$layerButtons.first()).data 'id'

    @__activeLayer__ = @layers.get id
    @activateLayerButton $target
    @$layeredSearchResults.html '<div class="loading-spinner"></div>'
    @fetchAndRenderActiveLayer()

    analytics.track.click "Switched to related artworks: #{@__activeLayer__.label()}" if e

  fetchAndRenderActiveLayer: ->
    if @activeLayer().artworks.length
      # Already fetched
      @renderLayer()
    else
      @activeLayer().artworks.
        fetch success: => @renderLayer()

  activeLayer: ->
    @__activeLayer__ or @layers.first()

  activateLayerButton: ($target) ->
    @$layerButtons.attr 'data-state', 'inactive'
    $target.attr 'data-state', 'active'

  renderLayer: ->
    # Ideally we should be removing this view before re-rendering
    # which would require a small refactor to the ArtworkColumns component
    @artworkColumnsView = new ArtworkColumnsView
      el: @$layeredSearchResults
      collection: @activeLayer().artworks
      numberOfColumns: 4
      gutterWidth: 40
      maxArtworkHeight: 400
      isOrdered: false
      seeMore: false
      allowDuplicates: true
      artworkSize: 'tall'

  postRender: ->
    @$layeredSearchResults  = @$('#layered-search-results')
    @$layerButtons          = @$('.layered-search-layer-button')
    @selectLayer() # Activate the first tab

  render: ->
    # If only one layer is returned it will be "For sale"
    # which, on its own, doesn't appear to have useful recommendations
    return @remove() unless @layers.length > 1

    @$el.html template(layers: @layers)
    @postRender()
    this
