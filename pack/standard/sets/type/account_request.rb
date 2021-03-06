# -*- encoding : utf-8 -*-

view :core do |args|
  links = []
  #ENGLISH
  if Account.create_ok?
    links << link_to( "Invite #{card.name}", Card.path_setting("/account/accept?card[key]=#{card.cardname.url_key}"), :class=>'invitation-link')
  end
  if Account.logged_in? && card.ok?(:delete)
    links << link_to( "Deny #{card.name}", path(:action=>:delete), :class=>'slotter standard-delete', :remote=>true )
  end

  process_content(_render_raw) +
  if (card.new_card?); '' else
    %{<div class="invite-links">
        <div><strong>#{card.name}</strong> requested an account on #{format_date(card.created_at) }</div>
        #{%{<div>#{links.join('')}</div> } unless links.empty? }
    </div>}
  end
end

event :block_user, :after=>:store, :on=>:delete do
  if account = Account[ self.id ]
    account.update_attributes :status=>'blocked'
  end
end
