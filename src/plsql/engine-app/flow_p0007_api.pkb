create or replace package body flow_p0007_api
as
    function get_error_message(
        pi_sqlcode in number,
        pi_sqlerrm in varchar2)
    return varchar2
    is
    l_constraint_name varchar2(255);
    l_constraint_message varchar2(32767);
    l_error_message varchar2(32767);
    begin
    if pi_sqlcode in (-1, -2091, -2290, -2291, -2292) then
        l_constraint_name := substr(pi_sqlerrm, instr(pi_sqlerrm, '(')+1, instr( pi_sqlerrm, ')') - instr( pi_sqlerrm,'(') -1);
        l_constraint_name := substr(l_constraint_name, instr(l_constraint_name, '.')+1);
        l_constraint_message := apex_lang.message(p_name => l_constraint_name);
        if (l_constraint_message != l_constraint_name) then
            l_error_message := l_constraint_message;
        end if;
    end if;
    if (l_error_message is null) then
        l_error_message := pi_sqlerrm;
    end if;

    return l_error_message;
    end get_error_message;

    procedure delete_diagram(
        pi_dgrm_id in flow_diagrams.dgrm_id%type,
        pi_cascade in varchar2
    )
    is
    begin
        if  pi_cascade = 'Y' then
            delete from flow_processes where prcs_dgrm_id = pi_dgrm_id;
        end if;
        delete from flow_diagrams where dgrm_id = pi_dgrm_id;
    end delete_diagram;

    function add_diagram_version(
        pi_dgrm_id in flow_diagrams.dgrm_id%type,
        pi_dgrm_version in flow_diagrams.dgrm_version%type
    ) return flow_diagrams.dgrm_id%type
    is
        l_dgrm_id flow_diagrams.dgrm_id%type;
        r_diagrams flow_diagrams%rowtype;
        l_dgrm_exist number;
    begin
        select * 
        into r_diagrams
        from flow_diagrams
        where dgrm_id = pi_dgrm_id;
        
        select count(*)
        into l_dgrm_exist
        from flow_diagrams
        where dgrm_name = r_diagrams.dgrm_name
        and dgrm_version = pi_dgrm_version;
        
        if (l_dgrm_exist = 0) then
            l_dgrm_id := flow_bpmn_parser_pkg.upload_diagram (
                pi_dgrm_name => r_diagrams.dgrm_name
                , pi_dgrm_version => pi_dgrm_version
                , pi_dgrm_category => r_diagrams.dgrm_category
                , pi_dgrm_content => r_diagrams.dgrm_content
                , pi_dgrm_status => flow_constants_pkg.gc_dgrm_status_draft
            );
            flow_bpmn_parser_pkg.parse(
                pi_dgrm_id => l_dgrm_id
            );
            return l_dgrm_id;
        else
            raise_application_error(-20000, '');
        end if;
    end add_diagram_version;

    procedure add_default_xml(
        pi_dgrm_id in flow_diagrams.dgrm_id%type
    )
    is
        l_default_xml clob := '<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI" id="Definitions_1wzb475" targetNamespace="http://bpmn.io/schema/b" exporter="bpmn-js (https://demo.bpmn.io)" exporterVersion="7.2.0">
<bpmn:process id="Process_0rxermh" isExecutable="false" />
<bpmndi:BPMNDiagram id="BPMNDiagram_1">
<bpmndi:BPMNPlane id="BPMNPlane_1" bpmnElement="Process_0rxermh" />
</bpmndi:BPMNDiagram>
</bpmn:definitions>
';
    begin
        update flow_diagrams set dgrm_content = l_default_xml where dgrm_id = pi_dgrm_id;
    end add_default_xml;

    procedure update_diagram_category(
        pi_dgrm_id in flow_diagrams.dgrm_id%type,
        pi_dgrm_category in flow_diagrams.dgrm_category%type
    )
    is
    begin
        update flow_diagrams d
        set d.dgrm_category = pi_dgrm_category,
            d.dgrm_last_update = systimestamp
        where d.dgrm_name = (select dgrm_name from flow_diagrams where dgrm_id = pi_dgrm_id)
        and (d.dgrm_category != pi_dgrm_category or (d.dgrm_category is null and pi_dgrm_category is not null) or (pi_dgrm_category is null and d.dgrm_category is not null))
        and d.dgrm_id != pi_dgrm_id;
    end update_diagram_category;

end flow_p0007_api;
/