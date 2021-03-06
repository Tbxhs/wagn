# -*- encoding : utf-8 -*-
module ScopeHelpers
  def scope_of section
    case section

    when /main card content/
      '#main > .card-slot > .content'

    when /main card header/
      '#main > .card-slot > .card-header'

    else
      raise "Can't find mapping from \"#{section}\" to a scope.\n" +
        "Now, go and add a mapping in #{__FILE__}"
    end
  end
end

World(ScopeHelpers)
