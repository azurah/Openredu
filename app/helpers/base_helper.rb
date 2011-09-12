require 'md5'

# Methods added to this helper will be available to all templates in the application.
module BaseHelper

  # Cria markup do sidebar a partir da navegação do contexto passado
  def sidebar(context)
    render_navigation(:context => context, :level => 1,
                      :renderer => ListSidebar)
  end

  # Cria markup das abas (compatível com o jQuery UI) a partir da navegação
  # do contexto passado
  def tabs(context, &block)
    locals = {
      :navigation => render_navigation(:context => context, :level => 2,
                                       :renderer => ListDetailed),
      :body => capture(&block)
    }

    render(:partial => 'shared/tabs', :locals => locals)
  end

  # Cria markup das sub abas (compatível com jQuery UI) a partir da navegação
  # do contexto passado
  def subtabs(context, &block)
    locals = {
      :navigation => render_navigation(:context => context, :level => 3),
      :body => capture(&block)
    }

    render(:partial => 'shared/subtabs', :locals => locals)
  end

  def error_for(object, method = nil, options={})
    if method
      err = instance_variable_get("@#{object}").errors[method].to_sentence rescue instance_variable_get("@#{object}").errors[method]
    else
      err = @errors["#{object}"] rescue nil
    end
    options.merge!(:class=>'errorMessageField',:id=>"#{[object,method].compact.join('_')}-error",
    :style=> (err ? "#{options[:style]}":"#{options[:style]};display: none;"))
    content_tag("p", err || "", options )
  end

  # Mostra todos os erros de um determinado atributo em forma de lista
  def concave_errors_for(object, method)
    errors = object.errors.get(method).collect do |msg|
      content_tag(:li, msg)
    end.join.html_safe

    content_tag(:ul, errors, :class => 'errors_on_field')
  end

  def type_class(resource)
    icons = ['3gp', 'bat', 'bmp', 'doc', 'css', 'exe', 'gif', 'jpg', 'jpeg', 'jar','zip',
             'mp3', 'mp4', 'avi', 'mpeg', 'mov', 'm4p', 'ogg', 'pdf', 'png', 'psd', 'ppt', 'txt', 'swf', 'wmv', 'xls', 'xml', 'zip']

    file_ext = resource.attachment_file_name.split('.').last if resource.attachment_file_name.split('.').length > 0
    if file_ext and icons.include? file_ext
      'ext_'+ file_ext
    else
      'ext_blank'
    end
  end

  # Sobrescrito para exibir mensagem de erro apenas com o nome
  # dos campos inválidos.
  def concave_error_messages_for(*params)
    options = params.extract_options!.symbolize_keys

    objects = Array.wrap(options.delete(:object) || params).map do |object|
      object = instance_variable_get("@#{object}") unless object.respond_to?(:to_model)
      object = convert_to_model(object)

      if object.class.respond_to?(:model_name)
        options[:object_name] ||= object.class.model_name.human.downcase
      end

      object
    end

    objects.compact!
    count = objects.inject(0) {|sum, object| sum + object.errors.count }

    unless count.zero?
      html = {}
      [:id, :class].each do |key|
        if options.include?(key)
          value = options[key]
          html[key] = value unless value.blank?
        else
          html[key] = 'error_explanation'
        end
      end
      options[:object_name] ||= params.first

      I18n.with_options :locale => options[:locale], :scope => [:activerecord, :errors, :template] do |locale|
        header_message = if options.include?(:header_message)
                           options[:header_message]
                         else
                           locale.t :header, :count => count, :model => options[:object_name].to_s.gsub('_', ' ')
                         end

        message = options.include?(:message) ? options[:message] : locale.t(:body)

        error_messages = objects.sum do |object|
          object.errors.collect { |attr, error| attr }.map do |attr|
            object.class.human_attribute_name(attr, :default => attr)
          end
        end.uniq.join(", ").html_safe



        contents = ''
        contents << content_tag(options[:header_tag] || :h2, header_message) unless header_message.blank?
        contents << content_tag(:p, message) unless message.blank?
        contents << content_tag(:p, error_messages, :class => "invalid_fields")

        content_tag(:div, contents.html_safe, html)
      end
    else
      ''
    end
  end



  def activity_name(item)
    link_user = link_to item.user.display_name, user_path(item.user)
    type = item.logeable_type.underscore
      case type
        when 'user'
         @activity = "acabou de entrar no redu" if item.log_action == "login"
         @activity = "atualizou seu status para: <span style='font-weight: bold;'>\"" + item.logeable_name + "\"</span>" if item.log_action == "update"

        when 'lecture'
          lecture = item.logeable
          link_obj = link_to(item.logeable_name, space_subject_lecture_path(lecture.subject.space, lecture.subject, lecture))

          @activity = "está visualizando a aula " + link_obj if item.log_action == "show"
          @activity = "criou a aula " + link_obj if item.log_action == "create"
          @activity =  "adicionou a aula " + link_obj + " ao seus favoritos" if item.log_action == "favorite"

      when 'exam'
          exam = item.logeable
          link_obj = link_to(item.logeable_name, space_subject_exam_path(exam.subject.space, exam.subject, exam))

          @activity = "acabou de responder o exame " + link_obj if item.log_action == "results"
          @activity = "está respondendo ao exame " + link_obj if item.log_action == "answer"
          @activity =  "criou o exame " + link_obj if item.log_action == "create"
          @activity =  "adicionou o exame " + link_obj + " ao seus favoritos" if item.log_action == "favorite"
      when 'space'
          link_obj = link_to(item.logeable_name, space_path(item.logeable_id))

          @activity =  "criou a disciplina " + link_obj if item.log_action == "create"
          @activity =  "adicionou a disciplina " + link_obj + " ao seus favoritos" if item.log_action == "favorite"
      when 'subject'
          link_obj = link_to(item.logeable_name, space_subject_path(item.logeable.space, item.logeable))

          @activity =  "criou o módulo " + link_obj if item.log_action == "create"
      when 'topic'
          @topic = Topic.find(item.logeable_id)
          link_obj = link_to(item.logeable_name, space_forum_topic_path(@topic.forum.space, @topic))

          @activity = "criou o tópico " + link_obj if item.log_action == 'create'
      when 'sb_post'
          @post = SbPost.find(item.logeable_id)
          link_obj = link_to(@post.topic.title, space_forum_topic_path(@post.topic.forum.space, @post.topic))

          @activity = "respondeu ao tópico " + link_obj if item.log_action == 'create'
      when 'event'
          @event = Event.find(item.logeable_id)
          link_obj = link_to(item.logeable_name, polymorphic_path([@event.eventable, @event]))

          @activity =  "criou o evento " + link_obj if item.log_action == "create"
      when 'bulletin'
          @bulletin = Bulletin.find(item.logeable_id)
          link_obj = link_to(item.logeable_name, polymorphic_path([@bulletin.bulletinable, @bulletin]))

          @activity =  "criou a notícia " + link_obj if item.log_action == "create"
      when 'myfile'
        @space = item.statusable
        @myfile = item.logeable
        link_obj = link_to @myfile.attachment_file_name,
          download_space_folder_url(@space, @myfile.folder,
                                    :file_id => @myfile)
        @activity =  "adicionou o arquivo #{link_obj} a disciplina #{link_to @space.name, @space}"
      else
          @activity = " atividade? "
      end
      @activity
  end

  def forum_page?
    %w(forums topics sb_posts spaces).include?(controller.controller_name)
  end

  def block_to_partial(partial_name, html_options = {}, &block)
    concat(render(:partial => partial_name, :locals => {:body => capture(&block), :html_options => html_options}))
  end

  def truncate_chars(text, length = 30, end_string = '...')
     return if text.blank?
     (text.length > length) ? text[0..length] + end_string  : text
  end

  def truncate_words(text, length = 30, end_string = '...')
    return if text.blank?
    words = strip_tags(text).split()
    words[0..(length-1)].join(' ') + (words.length > length ? end_string : '')
  end

  def truncate_words_with_highlight(text, phrase)
    t = excerpt(text, phrase)
    highlight truncate_words(t, 18), phrase
  end

  def excerpt_with_jump(text, end_string = ' ...')
    return if text.blank?
    doc = Hpricot( text )
    paragraph = doc.at("p")
    if paragraph
      paragraph.to_html + end_string
    else
      truncate_words(text, 150, end_string)
    end
  end

  def page_title
    app_base = Redu::Application.config.name
    tagline = " | #{Redu::Application.config.tagline}"

    title = app_base
    case controller.controller_name
      when 'base'
          title += tagline
                        when 'pages'
                          if @page and @page.title
                            title = @page.title + ' - ' + app_base + tagline
                          end
      when 'posts'
        if @post and @post.title
          title = @post.title + ' - ' + app_base + tagline
          title += (@post.tags.empty? ? '' : " - "+ t(:keywords) +": " + @post.tags[0...4].join(', ') )
          @canonical_url = user_post_url(@post.user, @post)
        end
      when 'users'
        if @user && !@user.new_record? && @user.login
          title = @user.login
          title += ' - ' + app_base + tagline
          @canonical_url = user_url(@user)
        else
          title = t(:showing_users) + ' - ' + app_base + tagline
        end
      when 'photos'
        if @user and @user.login
          title = @user.login + '\'s '+ t(:photos) +' - ' + app_base + tagline
        end
      when 'tags'
        case controller.action_name
          when 'show'
            title = @tags.map(&:name).join(', ') + ' '
            title += params[:type] ? params[:type].pluralize : t(:posts_photos_and_bookmarks)
            title += ' (Related: ' + @related_tags.join(', ') + ')' if @related_tags
            title += ' | ' + app_base
            @canonical_url = tag_url(URI.escape(@tags_raw, /[\/.?#]/)) if @tags_raw
          else
          title = 'Showing tags - ' + app_base + tagline
        end
      when 'categories'
        if @category and @category.name
          title = @category.name + ' '+ t(:posts_photos_and_bookmarks) +' - ' + app_base + tagline
        else
          title = t(:showing_categories) + ' - ' + app_base + tagline
        end
      when 'lectures'
      if @lecture and @lecture.name
        title = 'Aula: ' + @lecture.name + ' - ' + app_base + tagline
      else
        title = 'Mostrando Aulas' +' - ' + app_base + tagline
      end
      when 'exams'
      if @exam and @exam.name
        title = 'Exame: ' + @exam.name + ' - ' + app_base + tagline
      else
        title = 'Mostrando Exames' +' - ' + app_base + tagline
      end
      when 'spaces'
      if @space and @space.name
        title = @space.name + ' - ' + app_base + tagline
      else
        title = 'Mostrando Disciplinas' +' - ' + app_base + tagline
      end
      when 'skills'
        if @skill and @skill.name
          title = t(:find_an_expert_in) + ' ' + @skill.name + ' - ' + app_base + tagline
        else
          title = t(:find_experts) + ' - ' + app_base + tagline
        end
      when 'sessions'
        title = t(:login) + ' - ' + app_base + tagline
    end

    if @page_title
      title = @page_title + ' - ' + app_base + tagline
    elsif title == app_base
      title = t(:showing) + ' ' + controller.controller_name.capitalize + ' - ' + app_base + tagline
    end
    title.html_safe
  end

  def activities_line_graph(options = {})
    line_color = "0x628F6C"
    prefix  = ''
    postfix = ''
    start_at_zero = false
    swf = "/images/swf/line_grapher.swf?file_name=/statistics.xml;activities&line_color=#{line_color}&prefix=#{prefix}&postfix=#{postfix}&start_at_zero=#{start_at_zero}"

    code = <<-EOF
    <object width="100%" height="400">
    <param name="movie" value="#{swf}">
    <embed src="#{swf}" width="100%" height="400">
    </embed>
    </object>
    EOF
    code
  end

  def last_active
    session[:last_active] ||= Time.now.utc
  end

  def submit_tag(value = t( :save_changes ), options={} )
    or_option = options.delete(:or)
    return super + "<span class='button_or'>or " + or_option + "</span>" if or_option
    super
  end

  def avatar_for(user, size=32)
    image_tag user.avatar.url(:medium), :size => "#{size}x#{size}", :class => 'photo'
  end

  def feed_icon_tag(title, url)
    (@feed_icons ||= []) << { :url => url, :title => title }
    link_to image_tag('feed.png', :size => '14x14', :alt => t( :subscribe_to ) + " #{title}"), url
  end

  def search_posts_title
    returning(params[:q].blank? ? t(:recent_posts) : t(:searching_for) + " '#{h params[:q]}'") do |title|
      title << " by #{h User.find(params[:user_id]).display_name}" if params[:user_id]
      title << " in #{h Forum.find(params[:forum_id]).name}"       if params[:forum_id]
    end
  end

  def search_user_posts_path(rss = false)
    options = params[:q].blank? ? {} : {:q => params[:q]}
    options[:format] = :rss if rss
    [[:user, :user_id], [:forum, :forum_id]].each do |(route_key, param_key)|
      return send("#{route_key}_sb_posts_path", options.update(param_key => params[param_key])) if params[param_key]
    end
    options[:q] ? search_all_sb_posts_path(options) : send("all_#{prefix}sb_posts_path", options)
  end

  def time_ago_in_words_or_date(date)
    if date.to_date.eql?(Time.now.to_date)
      display = I18n.l(date.to_time, :format => :time_ago)
    elsif date.to_date.eql?(Time.now.to_date - 1)
      display = t(:yesterday)
    else
      display = I18n.l(date.to_date, :format => :date_ago)
    end
  end

  def owner_link
    if @space.owner
      link_to @space.owner.display_name, @space.owner
    else
      if current_user.can_be_owner? @space
        'Sem dono ' + link_to("(pegar)", take_ownership_space_path)
      else
        'Sem dono'
      end
      #TODO e se ninguem estiver apto a pegar ownership?
    end

  end

  def get_random_number
    SecureRandom.hex(4)
  end

  # Gera o nome do recurso (class_name) devidamente pluralizado de acordo com
  # a quantidade (qty)
  def resource_name(class_name, qty)
    case class_name
    when :myfile
        "#{qty > 1 ? "novos" : "novo"} #{pluralize(qty, 'arquivo').split(' ')[1]}"
    when :folder
        "#{qty > 1 ? "novos" : "novo"} #{pluralize(qty, 'arquivo').split(' ')[1]}"
    when :bulletin
        "#{qty > 1 ? "novas" : "nova"} #{pluralize(qty, 'notícia').split(' ')[1]}"
    when :event
        "#{qty > 1 ? "novos" : "novo"} #{pluralize(qty, 'evento').split(' ')[1]}"
    when :topic
        "#{qty > 1 ? "novos" : "novo"} #{pluralize(qty, 'tópico').split(' ')[1]} "
    when :subject
        "#{qty > 1 ? "novos" : "novo"} #{pluralize(qty, 'módulo').split(' ')[1]} "
    end
  end

  # Mostra tabela de preço de planos
  def pricing_table(plans=nil)
    plans ||= Plan::PLANS

    render :partial => "plans/plans", :locals => { :plans => plans }
  end

end

module AsyncJSHelper
  # Carrega asset de forma lazy.
  # Opções:
  #   type: pode ser js (default) ou css
  #   jammit: true se o package utuliza a infraestrutura do jammit (defalt false)
  #   clear: caso o arquivo já tenha sido incluido, tenta remover antes de
  #    adicionar novamente. Default frue
  def lazy_load(package, options = {}, &block)
    opts = {
      :type => :js,
      :jammit => false,
      :clear => true
    }.merge(options)

    if opts[:jammit]
      package = jammit(package, opts[:type])
    end
    package = package.to_a.flatten

    javascript_tag(:type => 'text/javascript') do
      result = ""

      if opts[:clear]
        result << <<-END
          $(document).ready(function(){
            $(document).removeLazyAssets({ paths : #{package.to_json}});
          });
        END
      end

      result << <<-END
        LazyLoad.#{opts[:type].to_s}(#{package.to_json}
      END

      if block.nil?
        result << ");"
      else
        result << ", function(){ #{capture(&block)}});"
      end

      result.html_safe
    end.html_safe
  end

  # Gera path ou lista de paths p/ um determinado asset (assets.yml)
  def jammit(pack, type)
    if should_package?
      Redu::Application.config.action_controller.asset_host + Jammit.asset_url(pack, type)
    else
      Jammit.packager.individual_urls(pack.to_sym, type)
    end
  end

  private

  def should_package?
    Jammit.package_assets && !(Jammit.allow_debugging && params[:debug_assets])
  end
end

ActionView::Base.send(:include, AsyncJSHelper)
