PageClassRegistrar.add(
  'AnnouncementPage',
  :controller => 'announcement_page',
  :icon => 'page_notice',
  :class_display_name => 'announcement',
  :class_description => "A little advertising",
  :class_group => 'wiki',
  :order => 4
)

self.load_once = false
