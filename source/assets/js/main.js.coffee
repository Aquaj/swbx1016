#= require chart

$(document).on 'ready', ->
  $(".down").click () ->
    console.log "Hello"
    $('html, body').animate {scrollTop: $("#content").offset().top}, 'slow'
  $('.js-slider').unslider(infinite: true)
