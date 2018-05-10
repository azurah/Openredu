# -*- encoding : utf-8 -*-
module ApplicationHelper
  # Helpers usados pelo gem de navegação (simple-navigation)
  CREATE_ACTIONS = ['new', 'create']
  def create_action_matcher(controller, &additional_condition)
    action_matcher({controller => CREATE_ACTIONS}, &additional_condition)
  end

  EDIT_ACTIONS = ['edit', 'update']
  def update_action_matcher(controller, &additional_condition)
    action_matcher({controller => EDIT_ACTIONS}, &additional_condition)
  end

  def action_matcher(controllers_actions, &additional_condition)
    lambda do
      controllers_actions.keys.include?(controller_name) &&
        controllers_actions[controller_name].include?(action_name) &&
        ( additional_condition.nil? ? true : additional_condition.call )
    end
  end

  # Function that fetches the current branch name from github and places in enviroment variable - hscs
  def get_branch_info
    branch_name = `git rev-parse --abbrev-ref HEAD`

    #last_commit = `git rev-parse --short HEAD`
    last_commit = 'placeholder'

    content_tag :span, :class => 'label-release label-doubts', :title => last_commit do
      branch_name
    end

  end

end
