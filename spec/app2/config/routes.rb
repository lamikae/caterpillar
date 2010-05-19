ActionController::Routing::Routes.draw do |map|
  map.caterpillar

  map.hungry_bear(
    'bear/hungry',
    { :controller => 'Bear',  :action => 'hungry' })
end
