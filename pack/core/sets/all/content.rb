
def content
  if new_card?
    template ? template.content : ''
  else
    current_revision.content
  end
end

def raw_content
  hard_template ? template.content : content
end

def chunk_list #override to customize by set
  :default
end

def selected_revision_id
  @selected_revision_id || current_revision_id || 0
end

def current_revision
  #return current_revision || Card::Revision.new
  if @cached_revision and @cached_revision.id==current_revision_id
  elsif ( Card::Revision.cache &&
     @cached_revision=Card::Revision.cache.read("#{cardname.safe_key}-content") and
     @cached_revision.id==current_revision_id )
  else
    rev = current_revision_id ? Card::Revision.find(current_revision_id) : Card::Revision.new()
    @cached_revision = Card::Revision.cache ?
      Card::Revision.cache.write("#{cardname.safe_key}-content", rev) : rev
  end
  @cached_revision
end

def previous_revision revision_id
  if revision_id
    rev_index = revisions.find_index do |rev|
      rev.id == revision_id
    end
    revisions[rev_index - 1] if rev_index.to_i != 0
  end
end

def revised_at
  (current_revision && current_revision.created_at) || Time.now
end

def creator
  Card[ creator_id ]
end

def updater
  Card[ updater_id || Card::AnonID ]
end

def drafts
  revisions.find(:all, :conditions=>["id > ?", current_revision_id])
end

def save_draft( content )
  clear_drafts
  revisions.create :content=>content
end

protected

def clear_drafts # yuck!
  connection.execute %{delete from card_revisions where card_id=#{id} and id > #{current_revision_id} }
end

