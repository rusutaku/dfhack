# repair him/her. type 'supermedic help' to show the descriptions.

args = $script_args.uniq

checkunit = lambda { |u|
    u.body.blood_count != 0 and
    not u.flags1.dead and
    not df.map_designation_at(u).hidden
}


find_nicknamed = lambda { |s|
    patients = []
    df.world.units.all.each { |u|
        if u.name.nickname == s
            next unless checkunit[u]
            patients << u
        end
    }
    puts "found #{patients.count} '#{s}'."
    return patients
}

clear_wounds = lambda { |u, f|
    if f or u.body.wounds.count > 0
    u.body.wounds = []
    u.body.wound_next_id = 1 #?
    puts "cleared all wounds."
    end
}

clear_requests = lambda { |u|
    return unless u.health
    u.health.body_part_flags.each { |flags|
        flags._whole = 0x0
    }
    puts "cleared treatment requests."
}

repair_stand = lambda { |u, f|
    return unless u.status2
    if f or u.status2.able_stand < 2
        u.status2.able_stand = 2
        puts "repaired lost stand ability."
    end
    if f or u.status2.able_stand_impair < 2
        u.status2.able_stand_impair = 2
        puts "repaired impaired stand ability."
    end
}

repair_grasp = lambda { |u, f|
    return unless u.status2
    if f or u.status2.able_grasp < 2
        u.status2.able_grasp = 2
        puts "repaired lost grasp ability."
    end
    if f or u.status2.able_grasp_impair < 2
        u.status2.able_grasp_impair = 2
        puts "repaired impaired grasp ability."
    end
}

wakeup = lambda { |u, f|
    return unless u.job.current_job
    jobtype = u.job.current_job.job_type
    if f or jobtype == :Rest
        u.job.current_job = nil
        u.counters.unconscious = 0
        puts "released from #{jobtype} job."
    end
}

rest = lambda { |u|
    u.job.current_job = DFHack::Job.cpp_new
    u.job.current_job.job_type = :Rest
    puts "commanded Rest job."
}

clear_syndromes = lambda { |u, f|
    if f or u.syndromes.active
        u.syndromes.active = []
        puts "cleared all syndromes."
    end
}

repair_him = lambda { |u, force|
    if args.include?("all") or args.empty?
        clear_wounds[u, force]
        clear_requests[u]
        repair_stand[u, force]
        repair_grasp[u, force]
        clear_syndromes[u, force]
        wakeup[u, force]
    else
        args.each { |arg|
            case arg
            when "wounds"
                clear_wounds[u, force]
            when "reqs"
                clear_requests[u]
            when "stand"
                repair_stand[u, force]
            when "grasp"
                repair_grasp[u, force]
            when "syndromes"
                clear_syndromes[u, force]
            when "wake"
                wakeup[u, force]
            when "rest"
                rest[u]
            end
        }
    end
}

if args.include?('man') or args.include?('help') or args.include?('?')
    puts "Some workarounds for health care bugs."
    puts "Please select a unit or select by following target option."
    puts "Options(target):"
    puts "  nick:x - execute repair function(s) to that nicknamed creature(s)."
    puts "           i.e. nick:foo means select all creature(s) nicknamed as 'foo'."
    puts "           you can use spaces by using quotes."
    puts "Options(functions):"
    puts "  all       - execute all following repair functions except 'rest'."
    puts "              no options is the same as this."
    puts "  wounds    - clear all wounds"
    puts "  reqs      - clear all treatment requests"
    puts "  stand     - force walkable (also impair)"
    puts "  grasp     - force graspable (also impair)"
    puts "  syndromes - clear all syndromes"
    puts "  wake      - release from 'Rest' job"
    puts "  rest      - command 'Rest' job"
    puts "Force Option:"
    puts "  -f or --force - force execute repair function(s)"
    puts ""
    puts "Usage:"
    puts "  supermedic wounds reqs stand wake"
    puts "    - repair the selecting patient without grasp"
    puts "  supermedic nick:""Nick"""
    puts "    - do all repairs to nicknamed as ""Nick"""
    puts "  supermedic wake -f"
    puts "    - force unstuck from current job."
    puts "  supermedic rest"
    puts "    - this will be useful for 'ignored by doctor' dwarf."
    puts "      ref. http://www.bay12games.com/dwarves/mantisbt/view.php?id=94"
else
    nick = ""
    patients = []
    force = false
    args = args.delete_if { |x|
        if /nick:(.+)/ =~ x
            nick = Regexp.last_match[1]
        elsif x == '-f' or x == '--force'
            force = true
        end
    }
    if /(['"])[^\1](.+)\1/ =~ nick # remove quotation chars
        nick = Regexp.last_match[2]
    end
    if nick.length > 0
        patients = find_nicknamed[nick]
    else
        unit = df.unit_find
        if not unit
            unit = df.curview.unit if df.curview.respond_to?(:unit)
            if df.curview.kind_of?(DFHack::ViewscreenLayerOverallHealthst)
                unit = unit[df.curview.layer_objects[0].cursor]
            end
        end
        patients << unit
    end
    if not patients.empty? and patients[0]
        patients.each { |u|
            puts "+ #{u.name} +"
            repair_him[u, force]
        }
    end
end
