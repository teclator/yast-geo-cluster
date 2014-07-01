# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2006 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

# File:	include/geo-cluster/dialogs.ycp
# Package:	Configuration of geo-cluster
# Summary:	Dialogs definitions
# Authors:	Dongmao Zhang <dmzhang@suse.com>
#
# $Id: dialogs.ycp 27914 2006-02-13 14:32:08Z locilka $
module Yast
  module GeoClusterDialogsInclude
    def initialize_geo_cluster_dialogs(include_target)
      Yast.import "UI"

      textdomain "geo-cluster"

      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "GeoCluster"
      Yast.import "Popup"
      Yast.import "IP"
      Yast.import "CWMFirewallInterfaces"

      Yast.include include_target, "geo-cluster/helps.rb"
    end

    def cluster_configure_layout(conf)
      VBox(
        HBox(
          InputField(
            Id(:confname),
            Opt(:hstretch),
            _("configuration file"),
            conf
          )
        ),
        HBox(
          InputField(
            Id(:arbitrator),
            Opt(:hstretch),
            _("arbitrator ip"),
            Ops.get(GeoCluster.global_files[conf], "arbitrator", "")
          ),
          ComboBox(
            Id(:transport),
            Opt(:hstretch, :notify),
            _("transport"),
            [Ops.get(GeoCluster.global_files[conf], "transport", "UDP")]
          ),
          InputField(
            Id(:port),
            Opt(:hstretch),
            _("port"),
            Ops.get(GeoCluster.global_files[conf], "port", "")
          )
        ),
        VBox(
          SelectionBox(Id(:site_box), _("site")),
          Left(
            HBox(
              PushButton(Id(:site_add), _("Add")),
              PushButton(Id(:site_edit), _("Edit")),
              PushButton(Id(:site_del), _("Delete"))
            )
          )
        ),
       VSpacing(1),
       VBox(
        Left(Label(_("ticket"))),
        Table(Id(:ticket_box), Header("ticket", "timeout", "retries", "weights", "expire", "acquire-after", "before-acquire-handler"), []),
        Left(
          HBox(
            PushButton(Id(:ticket_add), "Add"),
            PushButton(Id(:ticket_edit), "Edit"),
            PushButton(Id(:ticket_del), "Delete"))
        )),
        VBox(
          Right(
            HBox(
              PushButton(Id(:ok), _("OK")),
              PushButton(Id(:cancel_inner), _("Cancel"))
            )
          )
        )
      )
    end


    # return `cacel or a string
    def ip_address_input_dialog(title, value)
      ret = nil

      UI.OpenDialog(
        MarginBox(
          1,
          1,
          VBox(
            MinWidth(100, InputField(Id(:text), Opt(:hstretch), title, value)),
            VSpacing(1),
            Right(
              HBox(
                PushButton(Id(:ok), _("OK")),
                PushButton(Id(:cancel), _("Cancel"))
              )
            )
          )
        )
      )
      while true
        ret = UI.UserInput
        if ret == :ok
          val = Convert.to_string(UI.QueryWidget(:text, :Value))
          if IP.Check(val) == true
            ret = val
            break
          else
            Popup.Message(_("Please enter valid ip address"))
          end
        end
        break if ret == :cancel
      end
      UI.CloseDialog
      deep_copy(ret)
    end

    def ticket_input_dialog(ticket_hash)
      ret = nil

      ticket = ""
      acquireafter = ""
      timeout = ""
      retries = ""
      weights = ""
      expire = ""
      beforeah = ""

      if ticket_hash != {}
        if ticket_hash.size != 1
          return {}
        end

        ticket_hash.each do |tname, value|
          ticket = tname
          acquireafter = Ops.get_string(value,"acquire-after","")
          timeout = Ops.get_string(value,"timeout","")
          retries = Ops.get_string(value,"retries","")
          weights = Ops.get_string(value,"weights","")
          expire = Ops.get_string(value,"expire","")
          beforeah = Ops.get_string(value,"before-acquire-handler","")
        end
      end

      UI.OpenDialog(
        MarginBox(
          1,
          1,
          VBox(
            Label(_("Enter ticket and timeout")),
            HBox(
              InputField(Id(:ticket), Opt(:hstretch), _("ticket"), ticket),
            ),
            VSpacing(1),
            HBox(
              InputField(Id(:timeout), Opt(:hstretch), _("timeout"), timeout),
              HSpacing(2),
              InputField(Id(:retries), Opt(:hstretch), _("retries"), retries),
              HSpacing(2),
              InputField(Id(:weights), Opt(:hstretch), _("weights"), weights),
              HSpacing(2),
              InputField(Id(:expire), Opt(:hstretch), _("expire"), expire),
              HSpacing(2),
              InputField(Id(:acquireafter), Opt(:hstretch), _("acquire-after"), acquireafter),
              HSpacing(2),
              InputField(Id(:beforeah), Opt(:hstretch), _("before-acquire-handler"), beforeah)
            ),
            VSpacing(1),
            Right(
              HBox(
                PushButton(Id(:ok), _("OK")),
                PushButton(Id(:cancel), _("Cancel"))
              )
            )
          )
        )
      )

      while true
        if ticket != ""
          UI.ChangeWidget(Id(:ticket), :Enabled, false)
        end

        ret = UI.UserInput

        if ret == :ok
          ticket = UI.QueryWidget(:ticket, :Value).to_s

          timeout = UI.QueryWidget(:timeout, :Value).to_s
          expire = UI.QueryWidget(:expire, :Value).to_s
          acquireafter = UI.QueryWidget(:acquireafter, :Value).to_s
          retries = UI.QueryWidget(:retries, :Value).to_s
          weights = UI.QueryWidget(:weights, :Value).to_s
          beforeah = UI.QueryWidget(:beforeah, :Value).to_s

          num_timeout = Builtins.tointeger(timeout)
          num_expire = Builtins.tointeger(expire)
          num_acquireafter = Builtins.tointeger(acquireafter)
          num_retries = Builtins.tointeger(retries)
          num_weights = Builtins.tointeger(weights)

          if num_timeout == nil && timeout != ""
            Popup.Message(_("timeout is no valid"))
          elsif num_expire == nil && expire != ""
            Popup.Message(_("expire is no valid"))
          elsif num_acquireafter == nil && acquireafter != ""
            Popup.Message(_("acquireafter is no valid"))
          elsif num_retries == nil && retries != ""
            Popup.Message(_("retries is no valid"))
          elsif retries != "" && num_retries < 3
            Popup.Message(_("retries values lower than 3 is illegal"))
          elsif num_weights == nil && weights != ""
            Popup.Message(_("weights is no valid"))
          elsif ticket == ""
            Popup.Message(_("ticket can not be null"))
          else
            temp_ticket = {}
            temp_ticket["timeout"] = timeout
            temp_ticket["expire"] = expire
            temp_ticket["acquire-after"] = acquireafter
            temp_ticket["retries"] = retries
            temp_ticket["weights"] = weights
            temp_ticket["before-acquire-handler"] = beforeah

            ret = {ticket => deep_copy(temp_ticket)}
            break
          end
        end
        break if ret == :cancel
      end
      UI.CloseDialog
      deep_copy(ret)
    end

    #fill site_box with global_site
    def fill_sites_entries(sites)
      i = 0
      ret = 0
      current = 0
      items = []
      sites.each do |site|
        items = items.push(Item(Id(i), site))
        i += 1
      end
      current = UI.QueryWidget(:site_box, :CurrentItem).to_i
      current = i-1 if current >= i
      UI.ChangeWidget(:site_box, :Items, items)
      UI.ChangeWidget(:site_box, :CurrentItem, current)

      nil
    end

    #fill site_ticket with global_ticket
    def fill_ticket_entries(tickets)
      i = 0
      ret = 0
      current = 0
      items = []

      tickets.each do |ticket_hash|
        ticket_hash.each do |tname, value|

          acquireafter = Ops.get_string(value,"acquire-after","")
          timeout = Ops.get_string(value,"timeout","")
          retries = Ops.get_string(value,"retries","")
          weights = Ops.get_string(value,"weights","")
          expire = Ops.get_string(value,"expire","")
          beforeah = Ops.get_string(value,"before-acquire-handler","")

          items = items.push(Item(Id(i), tname, timeout, retries, weights, expire, acquireafter, beforeah))
          i += 1
        end
      end
      current = UI.QueryWidget(:ticket_box, :CurrentItem).to_i
      current = i-1 if current >= i
      UI.ChangeWidget(:ticket_box, :Items, items)
      UI.ChangeWidget(:ticket_box, :CurrentItem, current)

      nil
    end

    #fill confs with global_files
    def fill_conf_entries
      i = 0
      ret = 0
      current = 0
      items = []
      conf_list = []
      GeoCluster.global_files.each_key do |conf|
        conf_list.push(conf)
        items = items.push(Item(Id(i), conf))
        i += 1
      end
      current = UI.QueryWidget(:conf_box, :CurrentItem).to_i
      current = i-1 if current >= i

      UI.ChangeWidget(:conf_box, :Items, items)
      UI.ChangeWidget(:conf_box, :CurrentItem, current)

      deep_copy(conf_list)
    end

    def validate
      ret = true
      if Builtins.size(GeoCluster.global_site) == 0
        Popup.Message(_("site have to be filled"))
        return false
      end

      if Builtins.size(GeoCluster.global_ticket) == 0
        Popup.Message(_("ticket have to be filled"))
        return false
      end

      Builtins.foreach(GeoCluster.global_conf) do |key, value|
        if key == "arbitrator"
          if IP.Check(value) != true
            Popup.Message(_("arbitrator IP address is invalid!"))
            ret = false
            raise Break
          end
        end
        if key == "port"
          num = Builtins.tointeger(value)
          if num != nil && Ops.greater_than(num, 0) &&
              Ops.less_or_equal(num, 65535)
            next
          else
            Popup.Message(Builtins.sformat("%1 is invalid", key))
            ret = false
            raise Break
          end
        end
        if value == ""
          Popup.Message(Builtins.sformat("%1 should be filled", key))
          ret = false
          raise Break
        end
      end

      ret
    end

    def ServiceDialog
      ret = nil
      event = {}
      firewall_widget = CWMFirewallInterfaces.CreateOpenFirewallWidget(
        {
          #servie:geo-cluster is the  name of /etc/sysconfig/SuSEfirewall2.d/services/geo-cluster
          "services"        => [
            "service:booth"
          ],
          "display_details" => true
        }
      )
      firewall_layout = Ops.get_term(firewall_widget, "custom_widget", VBox())
      contents = VBox(
        VSpacing(1),
        Frame("firewall settings", firewall_layout),
        VStretch()
      )
      Wizard.SetContents(
        _("Geo Cluster(geo-cluster) firewall configure"),
        firewall_layout,
        Ops.get_string(@HELPS, "geo-cluster", ""),
        true,
        true
      )
      CWMFirewallInterfaces.OpenFirewallInit(firewall_widget, "")
      while true
        event = UI.WaitForEvent
        ret = Ops.get(event, "ID")
        if ret == :next
          CWMFirewallInterfaces.OpenFirewallStore(firewall_widget, "", event)
          break
        end

        if ret == :wizardTree
          ret = Convert.to_string(UI.QueryWidget(Id(:wizardTree), :CurrentItem))
        end

        if Builtins.contains(@DIALOG, Convert.to_string(ret))
          ret = Builtins.symbolof(Builtins.toterm(ret))
          break
        end

        if ret == :abort || ret == :cancel
          if ReallyAbort()
            return deep_copy(ret)
          else
            next
          end
        end
        break if ret == :back
        CWMFirewallInterfaces.OpenFirewallHandle(firewall_widget, "", event)
      end
      deep_copy(ret)
    end
    # Dialog for geo-cluster
    # Configure2 dialog
    # @return dialog result
    def ConfigureDialog(conf)
      # GeoCluster configure2 dialog caption
      caption = _("GeoCluster Configuration")

      # Wizard::SetContentsButtons(caption, contents, HELPS["c2"]:"",
      # 	    Label::BackButton(), Label::NextButton());

      ret = nil
      add_new_conf = false

      Wizard.SetContents(
        _("Geo Cluster configure"),
        cluster_configure_layout(conf),
        Ops.get_string(@HELPS, "booth", ""),
        false,
        false
      )

      current = 0
      temp_site = []
      temp_ticket = []

      if conf != ""
        if GeoCluster.global_files[conf]["site"]
          temp_site = deep_copy(GeoCluster.global_files[conf]["site"])
        end

        if GeoCluster.global_files[conf]["ticket"]
          GeoCluster.global_files[conf]["ticket"].each do |tname, value|
            temp_ticket.push({tname => deep_copy(value)})
          end
        end
      else
        add_new_conf = true
      end

      while true
        fill_sites_entries(temp_site)
        fill_ticket_entries(temp_ticket)

        if conf != ""
          UI.ChangeWidget(Id(:confname), :Enabled, false)
        elsif conf == "" && GeoCluster.global_files.empty?
          UI.ChangeWidget(Id(:confname), :Value, "booth")
        end

        if temp_site.size == 0
          UI.ChangeWidget(Id(:site_edit), :Enabled, false)
          UI.ChangeWidget(Id(:site_del), :Enabled, false)
        else
          UI.ChangeWidget(Id(:site_edit), :Enabled, true)
          UI.ChangeWidget(Id(:site_del), :Enabled, true)
        end

        if temp_ticket.size == 0
          UI.ChangeWidget(Id(:ticket_edit), :Enabled, false)
          UI.ChangeWidget(Id(:ticket_del), :Enabled, false)
        else
          UI.ChangeWidget(Id(:ticket_edit), :Enabled, true)
          UI.ChangeWidget(Id(:ticket_del), :Enabled, true)
        end

        ret = UI.UserInput

        if ret == :site_add
          ret = ip_address_input_dialog(
            _("Enter an IP address of your site"),
            ""
          )
          next if ret == :cancel
          temp_site.push(ret.to_s)
          next
        end

        if ret == :site_edit
          current = UI.QueryWidget(:site_box, :CurrentItem).to_i
          ret = ip_address_input_dialog(
            _("Edit IP address of your site"),
            temp_site[current]
          )
          next if ret == :cancel
          temp_site[current] = ret.to_s
          next
        end

        if ret == :site_del
          current = UI.QueryWidget(:site_box, :CurrentItem).to_i
          temp_site.delete_at(current)
          next
        end

        if ret == :ticket_add
          ret = ticket_input_dialog({})
          next if ret == :cancel

          dup_name = false
          ret.each_key do |tname|
            temp_ticket.each do |ticket|
              if ticket.include?(tname)
                Popup.Message(_("Ticket name already exist!"))
                dup_name = true
                break
              end
            end
          end
          next if dup_name

          temp_ticket.push(ret)
          next
        end

        if ret == :ticket_edit
          current = UI.QueryWidget(:ticket_box, :CurrentItem).to_i

          ret = ticket_input_dialog(temp_ticket[current])
          next if ret == :cancel
          temp_ticket[current] = ret
          next
        end

        if ret == :ticket_del
          current = UI.QueryWidget(:ticket_box, :CurrentItem).to_i
          temp_ticket.delete_at(current)
          next
        end

        if ret == :wizardTree
          Wizard.SelectTreeItem("choose_conf")
          next
          #ret = Convert.to_string(UI.QueryWidget(Id(:wizardTree), :CurrentItem))
        end

        next if Builtins.contains(@DIALOG, Convert.to_string(ret))

        # abort?
        if ret == :abort || ret == :back
          if ReallyAbort()
            break
          else
            next
          end

        elsif ret == :ok
          conf = UI.QueryWidget(:confname, :Value).to_s
          if conf == ""
            Popup.Message(_("Configuration name can not be null"))
            next
          elsif add_new_conf && GeoCluster.global_files.include?(conf)
            Popup.Message(_("Configuration name can not be duplicated."))
            next
          end

          arbitrator = UI.QueryWidget(:arbitrator, :Value).to_s
          if IP.Check(arbitrator) != true
            Popup.Message(_("arbitrator IP address is invalid!"))
            next
          end

          port = UI.QueryWidget(:port, :Value).to_s
          num_port = Builtins.tointeger(port)
          if num_port == nil || num_port <= 0 || num_port > 65535
            Popup.Message(_("port is invalid!"))
            next
          end

          transport = UI.QueryWidget(:transport, :Value).to_s
          if transport == ""
            Popup.Message(_("transport have to be filled!"))
            next
          end

          if temp_site.size == 0
            Popup.Message(_("site have to be filled!"))
            next
          end

          if temp_ticket.size == 0
            Popup.Message(_("ticket have to be filled!"))
            next
          end

          GeoCluster.global_files[conf] = {}

          GeoCluster.global_files[conf]["arbitrator"] = arbitrator
          GeoCluster.global_files[conf]["port"] = port
          GeoCluster.global_files[conf]["transport"] = transport

          GeoCluster.global_files[conf]["site"] = temp_site

          GeoCluster.global_files[conf]["ticket"] = {}
          temp_ticket.each do |ticket|
            GeoCluster.global_files[conf]["ticket"] = GeoCluster.global_files[conf]["ticket"].merge(ticket)
          end

          if add_new_conf && GeoCluster.global_del_confs.include?(conf)
            GeoCluster.global_del_confs.delete(conf)
          end
          break

        elsif ret == :cancel_inner
          break

        else
          Builtins.y2error("unexpected retcode: %1", ret)
          next
        end
      end

      deep_copy(ret)
    end

    # Dialog for geo-cluster
    # Choose config file dialog
    # @return dialog result
    def ChooseConfigureDialog
      # GeoCluster choose configure dialog caption
      caption = _("GeoCluster Configuration Select")

      # Wizard::SetContentsButtons(caption, contents, HELPS["c2"]:"",
      # 	    Label::BackButton(), Label::NextButton());

      config_box = VBox(
          SelectionBox(Id(:conf_box), _("Choose configuration file:")),
          Right(
            HBox(
                PushButton(Id(:conf_add), _("Add")),
                PushButton(Id(:conf_edit), _("Edit")),
                PushButton(Id(:conf_del), _("Delete"))
            )
          )
      )

      ret = nil
      current = 0
      conf_list = []

      while true
        Wizard.SelectTreeItem("choose_conf")

        # FIXME ugly work. Better use alias and function, see yast2 drbd.
        Wizard.SetContents(
          _("Geo Cluster configure"),
          config_box,
          Ops.get_string(@HELPS, "confs", ""),
          true,
          true
        )

        conf_list = fill_conf_entries
        ret = UI.UserInput

        if ret == :conf_add
          ret = ConfigureDialog("")
          next if ret == :cancel
          next
        end

        if ret == :conf_edit
          current = UI.QueryWidget(:conf_box, :CurrentItem).to_i
          ret = ConfigureDialog(conf_list[current])
          next if ret == :cancel
          next
        end

        if ret == :conf_del
          current = UI.QueryWidget(:conf_box, :CurrentItem).to_i

          GeoCluster.global_del_confs.push(conf_list[current])
          GeoCluster.global_files.delete(conf_list[current])
          next
        end

        if ret == :wizardTree
          ret = Convert.to_string(UI.QueryWidget(Id(:wizardTree), :CurrentItem))
        end

        # abort?
        if ret == :abort || ret == :cancel || ret == :back
          if ReallyAbort()
            break
          else
            next
          end
        elsif ret == :next
          break
        elsif Builtins.contains(@DIALOG, Convert.to_string(ret))
          ret = Builtins.symbolof(Builtins.toterm(ret))
          break
        else
          Builtins.y2error("unexpected retcode: %1", ret)
          next
        end
      end

      deep_copy(ret)
    end

  end
end
