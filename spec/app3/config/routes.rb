ActionController::Routing::Routes.draw do |map|
  map.adorable_otters(
    '/otters/adorable',
    { :controller => 'Otter', :action => 'adorable' }) 
end
