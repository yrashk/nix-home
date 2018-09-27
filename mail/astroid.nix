{ pkgs }:

{
  accounts =
  {
    yrashk =
    {
      additional_sent_tags = "";
      always_gpg_sign = "false";
      default = "true";
      email = "me@yrashk.com";
      gpgkey = "me@yrashk.com";
      name = "Yurii Rashkovskii";
      save_drafts_to = "/home/yrashk/.mail/yrashk/Drafts/";
      save_sent = "false";
      save_sent_to = "/home/yrashk/.mail/yrashk/Sent/cur/";
      select_query = "";
      sendmail = "${pkgs.msmtp}/bin/msmtp --read-envelope-from -i -t";
      signature_attach = "false";
      signature_default_on = "true";
      signature_file = "";
      signature_file_markdown = "";
      signature_separate = "false";
    };
  };
  astroid =
  {
    config =
    {
      version = "11";
    };
    debug =
    {
      dryrun_sending = "false";
    };
    hints =
    {
      level = "0";
    };
    log =
    {
      level = "info";
      stdout = "true";
      syslog = "false";
    };
    notmuch_config = "/home/yrashk/.notmuch-config";
  };
  attachment =
  {
    external_open_cmd = "xdg-open";
  };
  crypto =
  {
    gpg =
    {
      always_trust = "true";
      enabled = "true";
      path = "${pkgs.gnupg}/bin/gnupg";
    };
  };
  editor =
  {
    attachment_directory = "~";
    attachment_words = "attach";
    charset = "utf-8";
    cmd =
      "${pkgs.vimHugeX}/bin/vim -g --servername %2 --socketid %3 -f -c 'set ft=mail' '+set fileencoding=utf-8' '+set ff=unix' '+set enc=utf-8' '+set fo+=w' %1";
    external_editor = "false";
    markdown_processor = "marked";
    save_draft_on_force_quit = "true";
  };
  general =
  {
    time =
    {
      clock_format = "local";
      diff_year = "%x";
      same_year = "%b %-e";
    };
  };
  mail =
  {
    close_on_success = "false";
    format_flowed = "false";
    forward =
    {
      disposition = "inline";
      quote_line = "Forwarding %1's message of %2:";
    };
    message_id_fqdn = "";
    message_id_user = "";
    reply =
    {
      mailinglist_reply_to_sender = "true";
      quote_line = "Excerpts from %1's message of %2:";
    };
    send_delay = "2";
    sent_tags = "sent";
    user_agent = "default";
  };
  poll =
  {
    always_full_refresh = "false";
    interval = "60";
  };
  saved_searches =
  {
    history_lines = "1000";
    history_lines_to_show = "15";
    save_history = "true";
    show_on_startup = "false";
  };
  startup =
  {
    queries = (import ./queries);
  };
  terminal =
  {
    font_description = "default";
    height = "10";
  };
  thread_index =
  {
    cell =
    {
      authors_length = "20";
      background_color_marked = "#fff584";
      background_color_marked_selected = "#bcb559";
      background_color_selected = "";
      date_length = "10";
      font_description = "default";
      hidden_tags = "attachment,flagged,unread";
      line_spacing = "2";
      message_count_length = "4";
      subject_color = "#807d74";
      subject_color_selected = "#000000";
      tags_alpha = "0.5";
      tags_length = "80";
      tags_lower_color = "#333333";
      tags_upper_color = "#e5e5e5";
    };
    page_jump_rows = "6";
    sort_order = "newest";
  };
  thread_view =
  {
    allow_remote_when_encrypted = "false";
    default_save_directory = "~";
    expand_flagged = "true";
    gravatar =
    {
      enable = "true";
    };
    indent_messages = "false";
    mark_unread_delay = "0.5";
    open_external_link = "xdg-open";
    open_html_part_external = "false";
    preferred_html_only = "false";
    #preferred_type = "html";
  };
}
