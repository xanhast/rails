# -*- coding: utf-8 -*-
require "cases/helper"
require 'support/connection_helper'
require 'active_record/base'
require 'active_record/connection_adapters/postgresql_adapter'

class PostgresqlDomainTest < ActiveRecord::TestCase
  include ConnectionHelper

  class PostgresqlDomain < ActiveRecord::Base
    self.table_name = "postgresql_domains"
  end

  def setup
    @connection = ActiveRecord::Base.connection
    @connection.transaction do
      @connection.execute "CREATE DOMAIN custom_money as numeric(8,2)"
      @connection.create_table('postgresql_domains') do |t|
        t.column :price, :custom_money
      end
    end
  end

  teardown do
    @connection.execute 'DROP TABLE IF EXISTS postgresql_domains'
    @connection.execute 'DROP DOMAIN IF EXISTS custom_money'
    reset_connection
  end

  def test_column
    column = PostgresqlDomain.columns_hash["price"]
    assert_equal :decimal, column.type
    assert_equal "custom_money", column.sql_type
    assert column.number?
    assert_not column.text?
    assert_not column.binary?
    assert_not column.array
  end

  def test_domain_acts_like_basetype
    PostgresqlDomain.create price: ""
    record = PostgresqlDomain.first
    assert_nil record.price

    record.price = "34.15"
    record.save!

    assert_equal BigDecimal.new("34.15"), record.reload.price
  end
end
