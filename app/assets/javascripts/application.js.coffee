#= require libs/modernizr-2.8.3
#= require libs/unslider-min
#= require chart
#= require_self

$(document).on 'ready', ->
  $(".down").click () ->
    $('html, body').animate {scrollTop: $("#content").offset().top}, 'slow'
  $('.js-slider').unslider(infinite: true)
