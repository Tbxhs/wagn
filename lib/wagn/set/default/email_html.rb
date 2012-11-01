module Wagn::Set::Default::EmailHtml
  class Wagn::Views
    format :email

    define_view :missing        do |args| '' end
    define_view :closed_missing do |args| '' end
  end
end
