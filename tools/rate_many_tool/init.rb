
PageClassRegistrar.add(
  'RateManyPage',
  :controller => 'rate_many_page',
  :model => 'Poll',
  :icon => 'page_approval',
  :class_display_name => 'approval vote',
  :class_description => :approval_vote_class_description,
  :class_group => 'vote',
  :order => 10
)

#self.override_views = true
self.load_once = false

