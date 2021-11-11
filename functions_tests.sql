
-- Выдать все города по регионам
declare
    v_data         KOTLYAROV_DM.TOWNS%rowtype;
    v_towns_cursor sys_refcursor;
begin
    v_towns_cursor := KOTLYAROV_DM.get_towns_by_region(1);

    loop
        fetch v_towns_cursor into v_data;
        exit when v_towns_cursor%notfound;

        DBMS_OUTPUT.PUT_LINE('Town name ' || v_data.name || ', region ID ' || v_data.ID_REGION);
    end loop;
    close v_towns_cursor;
end;

-- Выдать все специальности (неудаленные),
-- в которых есть хотя бы один доктор (неудаленный),
-- которые работают в больницах (неудаленных)
declare
    v_data           KOTLYAROV_DM.specialities%rowtype;
    v_doctors_cursor sys_refcursor;
begin
    v_doctors_cursor := KOTLYAROV_DM.get_doctors_by_specialty(1);

    loop
        fetch v_doctors_cursor into v_data;
        exit when v_doctors_cursor%notfound;

        DBMS_OUTPUT.PUT_LINE('ID ' || v_data.ID || ', AGE_GROUP ' || v_data.ID_AGE_GROUP);
    end loop;
    close v_doctors_cursor;
end;

-- *Выдать все больницы (неудаленные) конкретной специальности (1) с пометками о доступности, кол-ве врачей;
-- отсортировать по типу: частные выше,
-- по кол-ву докторов: где больше выше,
-- по времени работы: которые еще работают выше
--
-- status 0 = недоступно
declare
    type hospital_info is record
                          (
                              id              number,
                              id_type         number,
                              name            varchar2(100),
                              id_organization number,
                              status          number,
                              doc_count       number
                          );

    v_data                 hospital_info;
    v_hospital_info_cursor sys_refcursor;
begin
    v_hospital_info_cursor := KOTLYAROV_DM.get_hospitals_by_speciality();

    loop
        fetch v_hospital_info_cursor into v_data;
        exit when v_hospital_info_cursor%notfound;

        DBMS_OUTPUT.PUT_LINE('ID ' || v_data.ID || ', name ' || v_data.name);
    end loop;
    close v_hospital_info_cursor;
end;

-- Выдать всех врачей (неудаленных) конкретной больницы,
-- отсортировать по квалификации: у кого есть выше,
-- по участку: если участок совпадает с участком пациента, то такие выше
declare
    v_data           KOTLYAROV_DM.DOCTORS%rowtype;
    v_doctors_cursor sys_refcursor;
begin
    v_doctors_cursor := KOTLYAROV_DM.get_doctors_by_hospital(
            p_id_hospital => 1,
            p_area => 'area 2'
        );

    loop
        fetch v_doctors_cursor into v_data;
        exit when v_doctors_cursor%notfound;

        DBMS_OUTPUT.PUT_LINE('ID ' || v_data.ID || ', AREA ' || v_data.AREA);
    end loop;
    close v_doctors_cursor;
end;

-- Выдать все талоны конкретного врача (1), не показывать талоны которые начались раньше текущего времени
declare
    v_data           KOTLYAROV_DM.TICKETS%rowtype;
    v_tickets_cursor sys_refcursor;
begin
    v_tickets_cursor := KOTLYAROV_DM.get_tickets_by_doctor(1);

    loop
        fetch v_tickets_cursor into v_data;
        exit when v_tickets_cursor%notfound;

        DBMS_OUTPUT.PUT_LINE('ID ' || v_data.ID || ', AREA ' || v_data.TIME_END);
    end loop;
    close v_tickets_cursor;
end;

-- выдать документы
declare
    v_document         KOTLYAROV_DM.patient_documents%rowtype;
    v_documents_cursor sys_refcursor;
begin
    v_documents_cursor := KOTLYAROV_DM.get_documents_by_patient(
            p_id_patient => 4,
            p_id_document_type => 2
        );

    loop
        fetch v_documents_cursor into v_document;
        exit when v_documents_cursor%notfound;

        dbms_output.put_line('Document patient ID ' || v_document.id || ', document type ' ||
                             v_document.ID_DOCUMENT_TYPE ||
                             ', document name ' || v_document.NAME);
    end loop;

    close v_documents_cursor;
end;

-- выдать расписание больниц
declare
    type t_hospital_work_times is table of KOTLYAROV_DM.HOSPITAL_WORK_TIMES%rowtype;
    v_hospital_work_times_cursor sys_refcursor;
begin
    v_hospital_work_times_cursor := KOTLYAROV_DM.get_hospitals_work_time(
            p_id_hospital => 1
        );
    loop
        declare
            v_work_time KOTLYAROV_DM.HOSPITAL_WORK_TIMES%rowtype;
        begin
            fetch v_hospital_work_times_cursor into v_work_time;
            exit when v_hospital_work_times_cursor%notfound;

            dbms_output.put_line('Hospital ID ' || v_work_time.ID_HOSPITAL || ', week day ' ||
                                 v_work_time.ID_WEEK_DAY ||
                                 ', begin time ' || v_work_time.BEGIN_TIME || ', end time ' ||
                                 v_work_time.END_TIME);
        end;
    end loop;
end;

-- выдать журнал пациента
declare
    v_patient_journals        KOTLYAROV_DM.PATIENT_JOURNALS%rowtype;
    v_patient_journald_cursor sys_refcursor;
begin
    v_patient_journald_cursor := KOTLYAROV_DM.get_patient_journald_by_patient_id(4);

    loop
        fetch v_patient_journald_cursor into v_patient_journals;
        exit when v_patient_journald_cursor%notfound;

        dbms_output.put_line('Patient ID ' || v_patient_journals.ID_PATIENT || ', ticket ID ' ||
                             v_patient_journals.ID_TICKET ||
                             ', ticket status ' || v_patient_journals.STATUS);
    end loop;

    close v_patient_journald_cursor;
end;

-- Создать метод записи с проверками пациента
--    на соответствие всем пунктам для записи
declare
    v_result boolean;
begin
    v_result := KOTLYAROV_DM.REQUEST(
            p_id_patient => 4,
            p_id_ticket => 2480
        );

    if (v_result) then
        DBMS_OUTPUT.PUT_LINE('All ok');
    else
        DBMS_OUTPUT.PUT_LINE('Patient not suitable for this ticket');
    end if;
end;

-- Пишем функцию отмены записи
declare
    v_result boolean;
begin
    v_result := KOTLYAROV_DM.CANCEL(
            p_id_patient => 4,
            p_id_ticket => 2480
        );

    if (v_result) then
        DBMS_OUTPUT.PUT_LINE('All ok');
    else
        DBMS_OUTPUT.PUT_LINE('Error cancelling');
    end if;
end;