# -*- encoding : utf-8 -*-
require 'digest'

class User < ActiveRecord::Base

  # Virtual attribute for the unencrypted password
  attr_accessor :password, :name

  validates :card_id,    :presence=>true, :uniqueness=>true
  validates :account_id, :presence=>true, :uniqueness=>true

  validates :email, :presence=>true, :if=>:email_required?,
    :uniqueness => { :scope   => :login                                      },
    :format     => { :with    => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i },
    :length     => { :maximum => 100                                         }
  
  validates :password, :presence=>true, :confirmation=>true, :if=>:password_required?,
    :length => { :within => 5..40 }
  validates :password_confirmation, :presence=>true, :if=>:password_required?
  
    

  before_validation :downcase_email!
  before_save :encrypt_password
  after_save :reset_instance_cache

  class << self
    def delete_cardless
      where( Card.where( :id=>arel_table[:card_id] ).exists.not ).delete_all
    end
  end

#~~~~~~~ Instance

  def reset_instance_cache
    Account.reset_cache_item card_id, email
  end

  def save_with_card card
    User.transaction do
      card = card.refresh
      account = card.fetch :trait=>:account, :new=>{}
      if card.save
        if account.save
          self.account_id = account.id
          self.card_id = card.id
          save
        end
      end

      account.errors.each do |key,err|
        card.errors.add key,err
      end
      self.errors.each do |key,err|
        card.errors.add key,err
      end
      if card.errors.any?
Rails.logger.warn "errors in save w/carc #{card.inspect}"
        account.expire_pieces
        raise ActiveRecord::Rollback 
      end
      true
    end
  end

  def accept card, email_args
    Account.as_bot do #what permissions does approver lack?  Should we check for them?
      card.type_id = Card::UserID # Invite Request -> User
      self.status='active'
      generate_password
      r=save_with_card(card)
      #Rails.logger.warn "accept #{inspect}, #{card.inspect}, #{self.errors.full_messages*", "} R:#{r}"; r
    end
    #card.save #hack to make it so last editor is current user.
    self.send_account_info(email_args) if card.errors.empty?
  end

  def send_account_info args
    raise Wagn::Oops, "subject and message required" unless args[:subject] && args[:message]
    begin
      args.merge! :to => self.email, :password => self.password
      #warn "account infor args: #{args}"
      message = Mailer.account_info Card[card_id], args
      message.deliver
    rescue Exception=>e
      Airbrake.notify e if Airbrake.configuration.api_key
      Rails.logger.info("ACCOUNT INFO DELIVERY FAILED: \n #{args.inspect}\n   #{e.message}, #{e.backtrace*"\n"}")
    end
  end

  def anonymous?; card_id == Card::AnonID end

  def active?   ; status=='active'  end
  def blocked?  ; status=='blocked' end
  def built_in? ; status=='system'  end
  def pending?  ; status=='pending' end

  # blocked methods for legacy boolean status
  def blocked= block
    if block == true
      self.status = 'blocked'
    elsif !built_in?
      self.status = 'active'
    end
  end

  def authenticated?(password)
    crypted_password == encrypt(password) and active?
  end

  PW_CHARS = ['A'..'Z','a'..'z','0'..'9'].map(&:to_a).flatten

  def generate_password
    self.password_confirmation = self.password =
      9.times.map { PW_CHARS[rand*61] }*''
  end

  def to_s
    "#<#{self.class.name}:#{login.blank? ? email : login}}>"
  end

  def mocha_inspect
    to_s
  end

  #before validation
  def downcase_email!
    if e = self.email and e != e.downcase
      self.email=e.downcase
    end
  end

#protected

  # Encrypts the password with the user salt
  def encrypt(password)
    Account.encrypt(password, salt)
  end

  # before save
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  def email_required?
    !built_in?
  end

  def password_required?
    !built_in? &&
    !pending?  &&
    #not_openid? &&
    (crypted_password.blank? or not password.blank?)
  end

end

