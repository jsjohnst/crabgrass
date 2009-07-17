module UrlHelper

  ##
  ## PSEUDO ROUTE HELPERS
  ## 

  #
  # Unlike normal route helpers (ie the ones autogenerated by named routes),
  # these helpers generate hashes. I like being able to easily refer to named
  # routes but to keep the results as a params hash. This is useful for all
  # sorts of things, like testing if a particular url is active or not.
  #

  def groups_params(options={})
    options[:id] ||= @group
    return networks_params(options) if options[:id] and options[:id].network?
    {:controller => '/groups', :action => nil}.merge(options)
  end

  def networks_params(options={})
    {:controller => '/networks', :action => nil, :id => @group}.merge(options)
  end

  def group_directory_params(options={})
    {:controller => '/groups/directory', :action => nil}.merge(options)
  end

  def committees_params(options={})
    {:controller => '/groups/committees', :action => nil, :id => @group}.merge(options)
  end

  def councils_params(options={})
    {:controller => '/groups/councils', :action => nil, :id => @group}.merge(options)
  end

  def groups_profiles_params(options={})
    {:controller => '/groups/profiles', :action => nil, :id => @group}.merge(options)
  end

  def groups_memberships_params(options={})
    {:controller => '/groups/memberships', :action => nil, :id => @group}.merge(options)
  end

  def groups_features_params(options={})
    {:controller => '/groups/features', :action => nil, :id => @group}.merge(options)
  end
 
  def me_params(options={})
    if options[:action].to_sym == :search
      options.delete(:action)
      {:controller => '/me/search'}.merge(options)
    else
      {:controller => '/me'}.merge(options)
    end
  end

  # for every method xxx_params, create xxx_url
  instance_methods.grep(/_params$/).each do |method|
    define_method(method.sub('params', 'url')) {|*args| url_for(send(method, *args))}
  end

  # first arg is options hash, remaining args are used for the path.
  def group_search_url(*args)
    opts = {
      :id => @group,
      :action => 'search',
      :controller => 'groups'
    }
    if args.first.is_a? Hash
      opts.merge!(args.shift)
    end
    if opts[:id] and opts[:id].respond_to?('network?')
      opts[:controller] = 'networks' if opts[:id].network?
    end
    opts[:path] ||= args if args.any?
    opts[:path] = parse_filter_path(opts[:path])
    opts
  end

  def person_search_url(*path)
    url_for_user(@user, :action => 'search', :path => parse_filter_path(path))
  end

  def me_search_url(*path)
    me_params(:action => 'search', :path => parse_filter_path(path))
  end

  ##
  ## REFERER
  ##

  def referer
    @referer ||= get_referer
  end
 	   
  def get_referer
    return '/' unless raw = request.env["HTTP_REFERER"]
    server = request.host_with_port
    prot = request.protocol
    if raw.starts_with?("#{prot}#{server}/")
      raw.sub(/^#{prot}#{server}/, '').sub(/\/$/,'')
    else
      '/'
    end
  end

  ##
  ## GROUPS
  ##

  def url_for_group(arg, options={})
    name_and_url_for_group(arg,options)[1]
  end

  # see function name_and_path_for_group for description of options
  def link_to_group(arg, options={})
    if arg.is_a? Integer
      @group_cache ||= {}
      # hacky fix for error when a page persists after it's group is deleted --af
      # what is this trying to do? --e
      if not @group_cache[arg]
        if Group.exists?(arg)
          @group_cache[arg] = Group.find(arg)
        else
          return ""
        end
      end
      # end hacky fix
      arg = @group_cache[arg]
    end
    
    display_name, path = name_and_url_for_group(arg,options)
    style = options[:style] || ""
    label = options[:label] || display_name
    klass = options[:class] || 'name_icon'
    avatar = ''
    if options[:avatar_as_separate_link] # not used for now
      avatar = link_to(avatar_for(arg, options[:avatar], options), :style => style)
    elsif options[:avatar]
      klass += " #{options[:avatar]}"
      if arg and arg.avatar
        url = avatar_url(:id => (arg.avatar||0), :size => options[:avatar])
      else
        url = avatar_url(:id => 0, :size => options[:avatar])
      end
      style = "background-image:url(#{url});" + style
    end
    avatar + link_to(label, path, :class => klass, :style => style)
  end


  # if you pass options[:full_name] = true, committees will have the string
  # "group+committee" (default does not include leading "group+")
  # 
  # options[:display_name] = true for groups will yield the descriptive name for display, if one exists
  #
  # This function accepts a string, a group_id (integer), or a class derived from a group
  #
  # If options[:text] = "boop %s beep", the group name will be 
  # substituted in for %s, and the display name will be "boop group_name beep"
  #
  # If options[:action] is not included it is assumed to be show, and otherwise
  # the link goes to "/group/action/group_name'
  def name_and_url_for_group(arg,options={})
    if arg.instance_of? Integer
      arg = Group.find(arg)
    elsif arg.instance_of? String
      name = arg
      group = Group.find_by_name(name)
      display_name = (group ? group.display_name : name)
    elsif arg.is_a? Group
      controller = 'networks' if arg.network?
      name = arg.name
      if options[:full_name]
        display_name = arg.full_name
      elsif options[:short_name]
        display_name = arg.name
      else
        display_name = arg.display_name
      end
    end

    display_name ||= name
    display_name = options[:text] % display_name if options[:text]
    action = options[:action] || 'show'
    if options[:path]
      if options[:path].is_a? String
        path = options[:path].split('/')
      elsif options[:path].is_a? Array
        path = options[:path]
      end
      path = path.select(&:any?)
    else
      path = nil
    end

    if action == 'show'
      url = "/#{name}"
    else
      controller ||= 'groups'
      url = {:controller => controller, :action => action, :id => name}
      url[:path] = path if path
    end
    [display_name, url]  
  end

  #def group_search_url(*path)
  #  url_for_group(@group, :action => 'search', :path => path)
  #end
  #
  #def group_trash_url(*path)
  #  url_for_group(@group, :action => 'trash', :path => path)
  #end

  ##
  ## USERS
  ##

  # arg might be a user object, a user id, or the user's login
  def login_and_path_for_user(arg, options={})
    if arg.is_a? Integer
      # this assumes that at some point simple id based finds will be cached in memcached
      user = User.find(arg)
      login = user.login 
      display = user.display_name
    elsif arg.is_a? String
      user = User.find_by_login(arg)
      login = arg
      display = user.nil? ? arg : user.display_name
    elsif arg.is_a? User
      login = arg.login
      display = arg.display_name
    end
    #link_to login, :controller => '/people', :action => 'show', :id => login if login
    action = options[:action] || 'show'
    if action == 'show'
      path = "/#{login}"
    else
      path = "/person/#{action}/#{login}"
    end
    [login, path, display]
  end
  
  def url_for_user(arg, options={})
    login, path, display = login_and_path_for_user(arg,options)
    path
  end
  
  # creates a link to a user, with or without the avatar.
  # avatars are displayed as background images, with padding
  # set on the <a> tag to make room for the image.
  # accepts:
  #  :avatar => [:small | :medium | :large]
  #  :label -- override display_name as the link text
  #  :style -- override the default style
  #  :class -- override the default class of the link (name_icon)
  def link_to_user(arg, options={})
    login, path, display_name = login_and_path_for_user(arg,options)
    style = options[:style] || ""                   # allow style override
    label = options[:login] ? login : display_name  # use display_name for label by default
    label = options[:label] || label                # allow label override
    klass = options[:class] || 'name_icon'
    style += " display:block" if options[:block]
    avatar = ''
    if options[:avatar_as_separate_link] # not used for now
      avatar = link_to(avatar_for(arg, options[:avatar], options), :style => style)
    elsif options[:avatar]
      klass += " #{options[:avatar]}"
      url = avatar_url(:id => (arg.avatar||0), :size => options[:avatar])
      style = "background-image:url(#{url});" + style
    end
    avatar + link_to(label, path, :class => klass, :style => style)
  end

  ##
  ## GENERIC PERSON OR GROUP 
  ##

  def url_for_entity(entity, options={})
    if entity.is_a? User
      url_for_user(entity, options)
    elsif entity.is_a? Group
      url_for_group(entity, options)
    end
  end

  def link_to_entity(entity, options={})
    if entity.is_a? User
      link_to_user(entity, options)
    elsif entity.is_a? Group
      link_to_group(entity, options)
    end
  end

  # Display a group or user, without a link. All such displays should be made by
  # this method.
  #
  # options:
  #   :avatar => nil | :xsmall | :small | :medium | :large | :xlarge (default: nil)
  #   :format => :short | :full | :both | :hover | :twolines (default: full)
  #   :block => false | true (default: false)
  #   :link => nil | true | url (default: nil)
  #   :class => passed through to the tag as html class attr
  #   :style => passed through to the tag as html style attr
  def display_entity(entity, options={})
    options = {:format => :full}.merge(options)
    display = nil; hover = nil
    options[:class] = [options[:class], 'entity'].join(' ')
    options[:block] = true if options[:format] == :twolines

    name = entity.name
    display_name = h(entity.display_name)
    both_names = h(entity.both_names)
    if options[:link]
      url = options[:link] === true ? url_for_entity(entity) : options[:link]
      name = link_to(name, url)
      display_name = link_to(display_name, url)
      both_name = link_to(both_names, url)
    end

    if options[:avatar]
      url = avatar_url(:id => (entity.avatar||0), :size => options[:avatar])
      options[:class] = [options[:class], "name_icon", options[:avatar]].compact.join(' ')
      options[:style] = [options[:style], "background-image:url(#{url})"].compact.join(';')
    end
    display, title, hover = case options[:format]
      when :short then [name,         display_name, nil]
      when :full  then [display_name, name,         nil]
      when :both  then [both_names,   nil,          nil]
      when :hover then [name,         nil,          display_name]
      when :twolines then ["<div class='name'>%s</div>%s"%[name, (display_name if name != display_name)], nil, nil]
    end
    if hover
      display += content_tag(:b,hover)
      options[:style] = [options[:style], "position:relative"].compact.join(';')
      # ^^ to allow absolute popup with respect to the name
    end
    element = options[:block] ? :div : :span
    content_tag(element, display, :style => options[:style], :class => options[:class], :title => title)
  end

  ##
  ## RSS SUPPORT
  ##

  def group_search_rss
    '<link rel="alternate" href="%s" title="%s" type="application/rss+xml" />' % [
       url_for(group_search_url(:action => params[:action], :path => current_rss_path)),
       "RSS Feed"[:rss_feed]
    ]
  end

  def me_rss
    '<link rel="alternate" href="/me/inbox/list/rss" title="%s %s" type="application/rss+xml" />' % [current_user.name, 'Inbox'[:inbox]]
  end

  # TODO: rewrite this using the rails 2.0 way, with respond_to do |format| ...
  # although, this will be hard, since it seems *path globbing doesn't work
  # with :format. 
  def handle_rss(locals)
    if rss_request?
      response.headers['Content-Type'] = 'application/rss+xml'   
      render :partial => '/pages/rss', :locals => locals
      return true
    else
      return false
    end
  end
  
  # return true if this is an rss request. Unfornately, for routes with
  # glob *paths, we can't use :format. the ParsedPath @path, however, does
  # a good job of identifying trailing format codes that are not otherwise
  # unparsable as part of the path.
  def rss_request?
    @path.format == 'rss'
  end

  # used to build an rss link from the current params[:path]
  def current_rss_path
    @path.format('rss') # returns a copy of @path with format set
  end

end
