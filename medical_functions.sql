-- Выдать все города по регионам
create or replace function KOTLYAROV_DM.get_towns_by_region(
    p_id_region number := null
)
    return sys_refcursor
as
    v_result sys_refcursor;
begin
    open v_result for
        SELECT *
        FROM KOTLYAROV_DM.TOWNS
        where (p_id_region is not null and p_id_region = id_region)
           or (p_id_region is null);

    return v_result;
end;

-- Выдать все специальности (неудаленные),
-- в которых есть хотя бы один доктор (неудаленный),
-- которые работают в больницах (неудаленных)
create or replace function KOTLYAROV_DM.get_doctors_by_specialty(
    p_age_group number := null
)
    return sys_refcursor
as
    v_result sys_refcursor;
begin
    open v_result for
        SELECT s.*
        FROM KOTLYAROV_DM.specialities s
                 INNER JOIN doctor_specialty ds on s.ID = ds.id_speciality
                 INNER JOIN doctors d on ds.id_doctor = d.id
                 INNER JOIN hospitals h on d.id_hospital = h.id
        WHERE s.deleted_at is not null
          AND d.deleted_at IS NULL
          AND h.deleted_at IS NULL
          AND ((p_age_group is not null and p_age_group = s.ID_AGE_GROUP) or (p_age_group is null));

    return v_result;
end;

-- *Выдать все больницы (неудаленные) конкретной специальности (1) с пометками о доступности, кол-ве врачей;
-- отсортировать по типу: частные выше,
-- по кол-ву докторов: где больше выше,
-- по времени работы: которые еще работают выше
--
-- status 0 = недоступно
create or replace function KOTLYAROV_DM.get_hospitals_by_speciality(
    p_id_specialty number := null,
    p_hospital_status number := null
)
    return sys_refcursor
as
    v_result sys_refcursor;
begin
    open v_result for
        SELECT h.ID,
               h.id_type,
               h.NAME,
               h.id_organization,
               h.STATUS,
               COUNT(d.id) AS doc_count
        FROM KOTLYAROV_DM.HOSPITALS h
                 INNER JOIN KOTLYAROV_DM.doctors d on d.id_hospital = h.id
                 INNER JOIN KOTLYAROV_DM.doctor_specialty ds on d.id = ds.id_doctor
                 INNER JOIN KOTLYAROV_DM.specialities s on ds.id_speciality = s.id
                 INNER JOIN KOTLYAROV_DM.HOSPITAL_WORK_TIMES hwt on h.ID = hwt.id_hospital
        WHERE h.deleted_at IS NULL
          AND hwt.END_TIME > to_char(systimestamp, 'hh24:mi')
          AND ((p_hospital_status is not null and p_hospital_status = h.status) or (p_hospital_status is null))
          AND ((p_id_specialty is not null and p_id_specialty = s.ID) or (p_id_specialty is null))
        GROUP BY hwt.END_TIME, h.id_type, h.id, h.NAME, h.id_organization, h.STATUS
        ORDER BY case when h.id_type = 1 then 1 else 0 end, doc_count DESC, hwt.END_TIME DESC;

    return v_result;
end;

-- Выдать всех врачей (неудаленных) конкретной больницы,
-- отсортировать по квалификации: у кого есть выше,
-- по участку: если участок совпадает с участком пациента, то такие выше
create or replace function KOTLYAROV_DM.get_doctors_by_hospital(
    p_id_hospital number := null,
    p_area varchar2 := null
)
    return sys_refcursor
as
    v_result sys_refcursor;
begin
    open v_result for
        SELECT d.*
        FROM KOTLYAROV_DM.DOCTORS d
                 INNER JOIN hospitals h on d.id_hospital = h.id
        WHERE d.deleted_at IS NULL
          and ((p_id_hospital is not null and p_id_hospital = h.id) or (p_id_hospital is null))
        ORDER BY d.degree desc,
                 CASE WHEN ((p_area is not null and p_area = d.AREA) or (p_area is null)) THEN 1 ELSE 0 END;

    return v_result;
end;

-- Выдать все талоны конкретного врача (1), не показывать талоны которые начались раньше текущего времени
create or replace function KOTLYAROV_DM.get_tickets_by_doctor(
    filter_id_doctor number := null
)
    return sys_refcursor
as
    v_result sys_refcursor;
begin
    open v_result for
        SELECT t.*
        FROM KOTLYAROV_DM.TICKETS t
                 INNER JOIN DOCTOR_SPECIALTY ds on t.ID_DOCTOR_SPECIALITY = ds.id
        WHERE t.TIME_BEGIN > current_date
          and ((filter_id_doctor IS NOT NULL and ds.ID_DOCTOR = filter_id_doctor) or (filter_id_doctor is null));

    return v_result;
end;

-- выдать документы
create or replace function KOTLYAROV_DM.get_documents_by_patient(
    p_id_patient number,
    p_id_document_type number := null
)
    return sys_refcursor
as
    v_result sys_refcursor;
begin
    open v_result for
        select *
        from KOTLYAROV_DM.PATIENT_DOCUMENTS
        where id = p_id_patient
          and ((p_id_document_type is not null and ID_DOCUMENT_TYPE = p_id_document_type) or
               (p_id_document_type is null));

    return v_result;
end;

-- выдать расписание больниц
create or replace function KOTLYAROV_DM.get_hospitals_work_time(
    p_id_hospital number := null,
    p_id_week_day number := null
)
    return sys_refcursor
as
    v_result sys_refcursor;
begin
    open v_result for
        select *
        from KOTLYAROV_DM.HOSPITAL_WORK_TIMES
        where ((p_id_hospital is not null and p_id_hospital = ID_HOSPITAL) or (p_id_hospital is null))
          and ((p_id_week_day is not null and p_id_week_day = ID_WEEK_DAY) or
               (p_id_week_day is null));
    return v_result;
end;

-- выдать журнал пациента
create or replace function KOTLYAROV_DM.get_patient_journald_by_patient_id(
    p_id_patient number := null
)
    return sys_refcursor
as
    v_result sys_refcursor;
begin
    open v_result for
        select *
        from KOTLYAROV_DM.PATIENT_JOURNALS
        where ((p_id_patient is not null and p_id_patient = ID_PATIENT) or (p_id_patient is null));
    return v_result;
end;

-- Создать метод записи с проверками пациента
--    на соответствие всем пунктам для записи
create or replace function KOTLYAROV_DM.request(
    p_id_patient number,
    p_id_ticket number
)
    return boolean
as
    v_count number;
begin
    select count(*)
    into v_count
    from KOTLYAROV_DM.PATIENT_JOURNALS
    where ID_PATIENT = p_id_patient
      and ID_TICKET = p_id_ticket
      and STATUS = 0;

    if (v_count != 0) then
        return false;
    end if;

    select count(t.ID)
    into v_count
    from KOTLYAROV_DM.TICKETS t
             INNER JOIN KOTLYAROV_DM.PATIENTS p on p.ID = p_id_patient
             INNER JOIN KOTLYAROV_DM.DOCTOR_SPECIALTY ds on ds.ID = t.ID_DOCTOR_SPECIALITY
             INNER JOIN KOTLYAROV_DM.SPECIALITIES s on s.ID = ds.ID_SPECIALITY
             INNER JOIN KOTLYAROV_DM.DOCTORS d on d.ID = ds.ID_DOCTOR
             INNER JOIN KOTLYAROV_DM.HOSPITALS h on h.ID = d.ID_HOSPITAL
             INNER JOIN KOTLYAROV_DM.AGE_GROUPS ag on ag.ID = s.ID_AGE_GROUP
             INNER JOIN KOTLYAROV_DM.SPECIALITY_GENDER sg on sg.ID_SPECIALITY = s.ID
             INNER JOIN KOTLYAROV_DM.PATIENT_DOCUMENTS pd on pd.ID_PATIENT = p_id_patient
    WHERE t.id = p_id_ticket
      and t.CLOSED = 0
      AND p.ID_GENDER = sg.ID_GENDER
      and t.TIME_BEGIN > sysdate
      and d.DELETED_AT is null
      and s.DELETED_AT is null
      and h.DELETED_AT is null
      and pd.ID_DOCUMENT_TYPE = 4 -- ОМС
      AND add_months(p.BIRTHDATE, ag.AGE_BEGIN * 12) <= sysdate
      AND add_months(p.BIRTHDATE, ag.AGE_END * 12) > sysdate;

    if (v_count = 1) then
        -- status 0 = OK, 1 = cancelled
        merge into KOTLYAROV_DM.PATIENT_JOURNALS pj
        using (
            select *
            from KOTLYAROV_DM.PATIENT_JOURNALS
        ) match
        on (pj.ID_PATIENT = match.ID_PATIENT and pj.ID_TICKET = match.ID_TICKET)
        when not matched then
            insert (ID_PATIENT, ID_TICKET) VALUES (p_id_patient, p_id_ticket)
        when matched then
            update set pj.STATUS = 0;

        update KOTLYAROV_DM.TICKETS set CLOSED = 1 where id = p_id_ticket;
        commit;

        return true;
    end if;

    return false;
end;


-- Пишем функцию отмены записи
create or replace function KOTLYAROV_DM.cancel(
    p_id_patient number,
    p_id_ticket number
)
    return boolean
as
    v_count number;
begin
    select count(*)
    into v_count
    from KOTLYAROV_DM.PATIENT_JOURNALS
    where ID_PATIENT = p_id_patient
      and ID_TICKET = p_id_ticket
      and STATUS = 0;

    if (v_count != 1) then
        return false;
    end if;

    select count(*)
    into v_count
    from KOTLYAROV_DM.TICKETS t
             INNER JOIN KOTLYAROV_DM.DOCTOR_SPECIALTY ds on ds.ID = t.ID_DOCTOR_SPECIALITY
             INNER JOIN KOTLYAROV_DM.SPECIALITIES s on s.ID = ds.ID_SPECIALITY
             INNER JOIN KOTLYAROV_DM.DOCTORS d on d.ID = ds.ID_DOCTOR
             INNER JOIN KOTLYAROV_DM.HOSPITAL_WORK_TIMES wt on wt.ID_HOSPITAL = d.ID_HOSPITAL
    where t.TIME_BEGIN > sysdate
      and t.id = p_id_ticket
      and wt.ID_WEEK_DAY = to_number(to_char(sysdate, 'D'))
      and wt.END_TIME > to_char(sysdate + ((1 / 24) * 2), 'hh24:mi');

    if (v_count != 1) then
        return false;
    end if;

    update KOTLYAROV_DM.PATIENT_JOURNALS
    set STATUS = 1
    where ID_PATIENT = p_id_patient
      and ID_TICKET = p_id_ticket;

    update KOTLYAROV_DM.TICKETS
    set CLOSED = 0
    where id = p_id_ticket;

    commit;

    return true;
end;