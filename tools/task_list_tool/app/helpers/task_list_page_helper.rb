module TaskListPageHelper

  ##
  ## show task
  ##

  # creates a checkbox tag for a task
  def task_checkbox(task)
    checkbox_id  = dom_id(task, 'check')
    checked = task.completed?
    next_state = checked ? 'pending' : 'complete'
    disabled = !current_user.may?(:edit,@page)
    click = remote_function(
      :url => page_xurl(@page, :action => 'mark_task_'+next_state, :id => task.id),
      :loading => hide(checkbox_id) + add_class_name(task, 'spinning')
    )
    check_box_tag(checkbox_id, '1', checked, :class => 'task_check', :onclick => click, :disabled => disabled)
  end

  # creates a link that expands to display the task details.
  def task_link_to_details(task)
    id = dom_id(task, 'details')
    name = task.name
    if logged_in?
      if task.created_at and logged_in_since < task.created_at
        name += content_tag(:b," (new)")
      elsif task.updated_at and logged_in_since < task.updated_at
        name += content_tag(:b," (modified)")
      end
    end
    link_to_function(name, "$('%s').toggle()" % id)
  end

  # makes links of the people assigned to a task like: "joe, janet, jezabel: "
  def task_link_to_people(task)
    links = task.users.collect{|user|
      user == current_user ? link_to(current_user.login, {:controller => 'me/tasks', :action => nil, :id => nil}, :class => 'hov') : link_to_user(user, :action => 'tasks', :class => 'hov')
    }.join(', ')
    #links.any? ? links+': ' : ''
  end

  # a button to hide the task detail
  def close_task_details_button(task)
    button_to_function "Close", hide(task, 'details')
  end

  # a button to delete the task
  def delete_task_details_button(task)
    function = remote_function(
      :url => page_xurl(@page, :action=>'destroy_task', :id=>task.id),
      :loading => show_spinner(task),
      :complete => hide(task)
    )
    button_to_function "Delete", function
  end

  # a button to replace the task detail with a tast edit form.
  def edit_task_details_button(task)
    function = remote_function(
      :url => page_xurl(@page, :action=>'edit_task', :id=>task.id),
      :loading => show_spinner(task)
    )
    button_to_function "Edit", function
  end

  def no_pending_tasks(visible)
    content_tag(:li, 'no pending tasks', :id => 'no_pending_tasks', :style => (visible ? nil : 'display:none'))
  end

  def no_completed_tasks(visible)
    content_tag(:li, 'no completed tasks', :id => 'no_completed_tasks', :style => (visible ? nil : 'display:none'))
  end

  ##
  ## edit task form
  ##

  def possible_users
    return @possible_users if @possible_users
    @possible_users = []
    if @page.users.with_access.any?
      @possible_users += @page.users.with_access
    end
    @page.groups.each do |group|
      @possible_users += group.users
    end
    @possible_users.uniq!
    return @possible_users
  end

  def options_for_task_edit_form(task)
    [{
      :url => page_xurl(@page, :action=>'update_task', :id => task.id),
      :loading  => show_spinner(task),
      :html => {}
    }]
  end

  def checkboxes_for_assign_people_to_task(task, selected=nil)
    collection_multiple_select('task', 'user_ids', possible_users, :id, :login, :outer_class=>'plain floatlist', :selected_items => selected)
  end

  def close_task_edit_button(task)
    button_to_function "Close", hide(task, 'details')
  end

  def delete_task_edit_button(task)
    delete_task_details_button(task)
  end

  def save_task_edit_button(task)
    submit_tag 'Save'
  end

  ###
  ### new task form
  ###

  def options_for_new_task_form
    [{
      :url      => page_xurl(@page, :action=>'create_task'),
      :html     => {:action => page_url(@page, :action=>'create_task'), :id => 'new-task-form'}, # non-ajax fallback
      :loading  => show_spinner('new-task'),
      :complete => hide_spinner('new-task'),
      :success => reset_form('new-task-form')
    }]
  end

end

