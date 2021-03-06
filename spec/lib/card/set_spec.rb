# -*- encoding : utf-8 -*-
require 'wagn/spec_helper'

module Card::Set::Right::Account # won't this conflict with a real set (and fail to provide controlled test?)
  Card::Set.register_set self
  extend Card::Set

  card_accessor :status, :default => "request", :type=>:phrase
  card_writer :write,    :default => "request", :type=>:phrase
  card_reader :read,     :default => "request", :type=>:phrase
end

describe Card do
  before do
    @account_card = Card['sara'].fetch(:trait=>:account)
  end

  describe "Read and write card attribute" do
    it "gets email attribute" do
      @account_card.status.should == 'request'
    end

    it "shouldn't have a reader method for card_writer" do
      @account_card.respond_to?( :write).should be_false
      @account_card.method( :write= ).should be
    end

    it "shouldn't have a reader method for card_reader" do
      @account_card.method( :read).should be
      @account_card.respond_to?( :read= ).should be_false
    end

    it "sets and saves attribute" do
      @account_card.write= 'test_value'
      @account_card.status= 'pending'
      @account_card.status.should == 'pending'
      Account.as_bot { @account_card.save }
      Card.cache.reset
      (tcard = Card['sara'].fetch(:trait=>:account)).should be
      tcard.status.should == 'pending'
      tcard.fetch(:trait=>:write).content.should == 'test_value'
    end
  end
end
