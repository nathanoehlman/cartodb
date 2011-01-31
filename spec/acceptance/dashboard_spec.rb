require File.expand_path(File.dirname(__FILE__) + '/acceptance_helper')

feature "Dashboard", %q{
  In order to allow users to manage their databases
  As a User
  I want to be able to visit my databases and manage them
} do

  scenario "Login and visit public tables wit no tables" do
    user = create_user :username => 'fulano'
    login_as user

    within(:css, "header") do
      page.should have_link("CartoDB")
      page.should have_content(user.email)
    end

    page.should have_content("Welcome back fulano")

    page.should have_content("You have not added any tags yet.")

    page.should have_no_selector("div.paginate")

    click_link_or_button('Public tables')

    page.should have_content("0 Public tables in cartoDB")
    page.should have_content("Ouch! There are not tables for your search")

  end

  scenario "Login and visit my dashboard and the public tables" do
    user = create_user
    the_other = create_user
    t = Time.now - 6.minutes
    Timecop.travel(t)
    20.times do |i|
      create_table :user_id => user.id, :name => "Table ##{20 - i}", :privacy => Table::PUBLIC,
                   :tags => 'personal'
    end
    20.times do |i|
      create_table :user_id => the_other.id, :name => "Other Table ##{20 - i}", :privacy => Table::PUBLIC,
                   :tags => 'vodka'
    end
    Timecop.travel(t + 1.minute)
    create_table :user_id => user.id, :name => 'My check-ins', :privacy => Table::PUBLIC,
                 :tags => "4sq, personal, feed aggregator"
    Timecop.travel(t + 2.minutes)
    create_table :user_id => user.id, :name => 'Downloaded movies', :privacy => Table::PRIVATE,
                 :tags => "movies, personal"
    Timecop.travel(t + 3.minutes)
    create_table :user_id => the_other.id, :name => 'Favourite restaurants', :privacy => Table::PUBLIC,
                 :tags => "restaurants"
    Timecop.travel(t + 4.minutes)
    create_table :user_id => the_other.id, :name => 'Secret vodkas', :privacy => Table::PRIVATE,
                 :tags => "vodka, drinking"

    Timecop.travel(t + 6.minutes)

    login_as user

    within(:css, "header") do
      page.should have_link("CartoDB")
      page.should have_content(user.email)
    end

    page.should have_css("footer")

    page.should have_css("ul.tables_list li.selected a", :text => "Your tables")
    page.should have_css("ul.tables_list li a", :text => "Public tables")

    page.should have_content("22 tables in your account")

    within("ul.your_tables li:eq(1)") do
      page.should have_link("downloaded_movies")
      page.should have_content("PRIVATE")
      page.should have_content("Last operation 4 minutes ago")
      within(:css, "span.tags") do
        page.should have_content("movies")
        page.should have_content("personal")
      end
    end

    within("ul.your_tables li:eq(2)") do
      page.should have_link("my_check_ins")
      page.should have_content("PUBLIC")
      page.should have_content("Last operation 5 minutes ago")
      within(:css, "span.tags") do
        page.should have_content("4sq")
        page.should have_content("personal")
        page.should have_content("feed aggregator")
      end
    end

    within("ul.your_tables li:eq(10).last") do
      page.should have_link("table_8")
      page.should have_content("PUBLIC")
      page.should have_content("Last operation 6 minutes ago")
      within(:css, "span.tags") do
        page.should have_content("personal")
      end
    end

    page.should have_content("BROWSE BY TAGS")
    page.should have_css("ul li:eq(1) a span", :text => "personal")
    page.should have_css("ul li a span", :text => "4sq")
    page.should have_css("ul li a span", :text => "feed aggregator")
    page.should have_css("ul li a span", :text => "movies")

    page.should have_no_selector("div.paginate a.previous")
    page.should have_selector("div.paginate a.next")
    within(:css, "div.paginate ul") do
      page.should have_css("li.selected a", :text => "1")
      page.should have_css("li a", :text => "2")
      page.should have_css("li a", :text => "3")
    end

    click_link_or_button('3')

    within("ul.your_tables li:eq(1)") do
      page.should have_link("table_19")
      page.should have_content("PUBLIC")
      within(:css, "span.tags") do
        page.should have_content("personal")
      end
    end

    within("ul.your_tables li:eq(2)") do
      page.should have_link("table_20")
      page.should have_content("PUBLIC")
      within(:css, "span.tags") do
        page.should have_content("personal")
      end
    end

    page.should have_selector("div.paginate a.previous")
    page.should have_no_selector("div.paginate a.next")
    within(:css, "div.paginate ul") do
      page.should have_css("li a", :text => "1")
      page.should have_css("li a", :text => "2")
      page.should have_css("li.selected a", :text => "3")
    end

    click_link_or_button('Previous')

    within("ul.your_tables li:eq(1)") do
      page.should have_link("table_9")
      page.should have_content("PUBLIC")
      within(:css, "span.tags") do
        page.should have_content("personal")
      end
    end

    within("ul.your_tables li:eq(2)") do
      page.should have_link("table_10")
      page.should have_content("PUBLIC")
      within(:css, "span.tags") do
        page.should have_content("personal")
      end
    end

    page.should have_selector("div.paginate a.previous")
    page.should have_selector("div.paginate a.next")
    within(:css, "div.paginate ul") do
      page.should have_css("li a", :text => "1")
      page.should have_css("li.selected a", :text => "2")
      page.should have_css("li a", :text => "3")
    end

    click_link_or_button('1')

    click_link_or_button('downloaded_movies')

    page.should have_css("h2", :text => 'downloaded_movies')
    page.should have_css("p.status", :text => 'PRIVATE')
    within(:css, "span.tags") do
      page.should have_content("movies")
      page.should have_content("personal")
    end

    page.should have_no_selector("footer")

    visit '/dashboard'
    click_link_or_button('Public tables')

    page.should have_content("21 Public tables in cartoDB")

    page.should have_content("BROWSE BY TAGS")
    page.should have_css("ul li:eq(1) a span", :text => "vodka")
    page.should have_css("ul li a span", :text => "restaurants")
    page.should have_no_css("ul li a span", :text => "drinking")

    within("ul.your_tables li:eq(1)") do
      page.should have_link("favourite_restaurants")
      page.should have_content("PUBLIC")
      within(:css, "span.tags") do
        page.should have_content("restaurants")
      end
    end

    page.should have_no_selector("div.paginate a.previous")
    page.should have_selector("div.paginate a.next")
    within(:css, "div.paginate ul") do
      page.should have_css("li.selected a", :text => "1")
      page.should have_css("li a", :text => "2")
      page.should have_css("li a", :text => "3")
    end

    click_link_or_button('Next')

    within("ul.your_tables li:eq(1)") do
      page.should have_link("other_table_10")
      page.should have_content("PUBLIC")
      within(:css, "span.tags") do
        page.should have_content("vodka")
      end
    end

    page.should have_selector("div.paginate a.previous")
    page.should have_selector("div.paginate a.next")
    within(:css, "div.paginate ul") do
      page.should have_css("li a", :text => "1")
      page.should have_css("li.selected a", :text => "2")
      page.should have_css("li a", :text => "3")
    end

    click_link_or_button('Previous')

    click_link_or_button('favourite_restaurants')

    page.should have_css("h2", :text => 'favourite_restaurants')
    page.should have_css("p.status", :text => 'PUBLIC')
    within(:css, "span.tags") do
      page.should have_content("restaurants")
    end

    visit '/dashboard'
    click_link_or_button('close session')
    page.current_path.should == login_path
  end
end