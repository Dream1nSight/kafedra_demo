insert into KOTLYAROV_DM.genders (id, name)
values (1, 'мужской');
insert into KOTLYAROV_DM.genders (id, name)
values (2, 'женский');
insert into KOTLYAROV_DM.genders (id, name)
values (3, 'девочка-мальчик');
insert into KOTLYAROV_DM.genders (id, name)
values (4, 'мальчик-девочка');

insert into KOTLYAROV_DM.age_groups (id, name, age_begin, age_end)
values (1, 'Младенчество', 0, 1);
insert into KOTLYAROV_DM.age_groups (id, name, age_begin, age_end)
values (2, 'Ранний возраст', 1, 3);
insert into KOTLYAROV_DM.age_groups (id, name, age_begin, age_end)
values (3, 'Школьный возраст', 7, 18);
insert into KOTLYAROV_DM.age_groups (id, name, age_begin, age_end)
values (4, 'Совершеннолетний', 16, 999);
insert into KOTLYAROV_DM.age_groups (id, name, age_begin, age_end)
values (5, 'Пожилой', 61, 75);

insert into KOTLYAROV_DM.week_days (id, name)
values (1, 'понедельник');
insert into KOTLYAROV_DM.week_days (id, name)
values (2, 'вторник');
insert into KOTLYAROV_DM.week_days (id, name)
values (3, 'среда');
insert into KOTLYAROV_DM.week_days (id, name)
values (4, 'четверг');
insert into KOTLYAROV_DM.week_days (id, name)
values (5, 'пятница');
insert into KOTLYAROV_DM.week_days (id, name)
values (6, 'суббота');
insert into KOTLYAROV_DM.week_days (id, name)
values (7, 'воскресенье');

insert into KOTLYAROV_DM.hospital_types (id, name)
values (1, 'частная');
insert into KOTLYAROV_DM.hospital_types (id, name)
values (2, 'государственная');

insert into KOTLYAROV_DM.document_types (id, type_name)
values (1, 'Пасспорт');
insert into KOTLYAROV_DM.document_types (id, type_name)
values (2, 'ИНН');
insert into KOTLYAROV_DM.document_types (id, type_name)
values (3, 'СНИЛС');


-- drop table KOTLYAROV_DM.REGIONS;
declare
    type t_number_array is table of number;
    a_regions             t_number_array;
    a_towns               t_number_array;
    a_organizations       t_number_array;
    a_hospitals           t_number_array;
    a_hospital_work_times t_number_array;
    a_doctors             t_number_array;
    a_specialities        t_number_array;
    a_tickets             t_number_array;
    a_users               t_number_array;
    a_patients            t_number_array;
    v_hospitals_count     number;
begin
    -- Regions
    DBMS_OUTPUT.PUT_LINE('Regions');
    for i in 1..2
        loop
            insert into KOTLYAROV_DM.regions (name, code) values ('region ' || i, i);
        end loop;
    commit;

    select id bulk collect
    into a_regions
    from KOTLYAROV_DM.regions;

    -- Towns
    DBMS_OUTPUT.PUT_LINE('Towns');
    for i in a_regions.first..a_regions.last
        loop
            --         DBMS_OUTPUT.PUT_LINE('Region ' || a_regions(i));
            for j in 1..2
                loop
                    insert into KOTLYAROV_DM.towns (name, id_region) values ('town ' || i || j, a_regions(i));
                end loop;
        end loop;
    commit;

    select id bulk collect
    into a_towns
    from KOTLYAROV_DM.towns;

    -- Organizations
    DBMS_OUTPUT.PUT_LINE('Organizations');
    for i in a_towns.first..a_towns.last
        loop
            --         DBMS_OUTPUT.PUT_LINE('Region ' || a_regions(i));
            for j in 1..2
                loop
                    insert into KOTLYAROV_DM.organizations (name, id_town)
                    values ('organization ' || i || j, a_towns(i));
                end loop;
        end loop;
    commit;

    select id bulk collect
    into a_organizations
    from KOTLYAROV_DM.organizations;

    -- Hospitals
    DBMS_OUTPUT.PUT_LINE('Hospitals');
    for i in a_organizations.first..a_organizations.last
        loop
            for j in 1..3
                loop
                    insert into KOTLYAROV_DM.hospitals (deleted_at, name, id_organization, status, id_type)
                    values (case
                                when DBMS_RANDOM.VALUE(0, 1) > 0.5 then to_date(
                                            '2019.' || floor(DBMS_RANDOM.VALUE(1, 12)) || '.01', 'yyyy.mm.dd')
                                end,
                            'hospital ' || i || j,
                            a_organizations(i),
                            floor(DBMS_RANDOM.VALUE(0, 100)),
                            floor(dbms_random.value(1, 3)));
                end loop;
        end loop;
    commit;

    select id bulk collect
    into a_hospitals
    from KOTLYAROV_DM.hospitals;

    v_hospitals_count := a_hospitals.COUNT;

    -- hospital_work_times
    DBMS_OUTPUT.PUT_LINE('hospital_work_times');
    for i in a_hospitals.first..a_hospitals.last
        loop
            for k in 1..7
                loop
                    insert into KOTLYAROV_DM.hospital_work_times (id_week_day, id_hospital, begin_time, end_time)
                    values (k, a_hospitals(i),
                            '0' || floor(DBMS_RANDOM.VALUE(6, 9)) || ':00',
                            floor(DBMS_RANDOM.VALUE(16, 19)) || ':00');
                end loop;
        end loop;
    commit;

    select id bulk collect
    into a_hospital_work_times
    from KOTLYAROV_DM.hospitals;

    -- doctors
    DBMS_OUTPUT.PUT_LINE('doctors');
    for i in a_hospitals.first..a_hospitals.last
        loop
            for j in 1..5
                loop
                    insert into KOTLYAROV_DM.doctors (deleted_at, area, degree, id_hospital, qualification, salary)
                    values (case
                                when DBMS_RANDOM.VALUE(0, 1) > 0.5 then to_date(
                                            '2019.' || floor(DBMS_RANDOM.VALUE(1, 12)) || '.01', 'yyyy.mm.dd')
                                end,
                            'area ' || j,
                            floor(DBMS_RANDOM.VALUE(1, 50)),
                            a_hospitals(i),
                            'bla bla',
                            floor(DBMS_RANDOM.VALUE(15000, 150000)));
                end loop;

        end loop;
    commit;

    select id bulk collect
    into a_doctors
    from KOTLYAROV_DM.doctors;

    -- doctors_reviews
    DBMS_OUTPUT.PUT_LINE('doctors_reviews');
    for i in a_doctors.first..a_doctors.last
        loop
            insert into KOTLYAROV_DM.doctors_reviews (id_doctor, review, rate)
            values (a_doctors(i),
                    'super!',
                    floor(DBMS_RANDOM.VALUE(0, 10)));
        end loop;
    commit;

    -- specialities
    DBMS_OUTPUT.PUT_LINE('specialities');
    declare
        v_id_speciality number;
    begin
        for i in a_doctors.first..a_doctors.last
            loop
                for j in 1..5
                    loop
                        insert into KOTLYAROV_DM.specialities (deleted_at, id_age_group)
                        values (case
                                    when DBMS_RANDOM.VALUE(0, 1) > 0.5 then to_date(
                                                '2019.' || floor(DBMS_RANDOM.VALUE(1, 12)) || '.01', 'yyyy.mm.dd')
                                    end,
                                floor(DBMS_RANDOM.VALUE(1, 5)))
                        returning ID into v_id_speciality;

                        insert into KOTLYAROV_DM.speciality_gender (id_speciality, id_gender)
                        values (v_id_speciality, floor(DBMS_RANDOM.VALUE(1, 4)));

                        insert into KOTLYAROV_DM.doctor_specialty (id_speciality, id_doctor)
                        values (v_id_speciality, a_doctors(i));
                    end loop;
            end loop;
    end;
    commit;

    select id bulk collect
    into a_specialities
    from KOTLYAROV_DM.specialities;

    -- tickets
    DBMS_OUTPUT.PUT_LINE('tickets');
    declare
        v_date_begin date;
    begin
        for i in a_specialities.first..a_specialities.last
            loop
                for j in 1..31
                    loop
                        v_date_begin := to_date(to_char(sysdate + j, 'yyyy.mm.dd') || ' 10:00', 'yyyy.mm.dd hh24:mi');
                        for k in 1..20
                            loop
                                insert into KOTLYAROV_DM.tickets (id_doctor_speciality, closed, time_begin, time_end)
                                values (a_specialities(i),
                                        case when DBMS_RANDOM.VALUE(0, 1) > 0.75 then 1 else 0 end,
                                        v_date_begin + ((30 * (k - 1) / 24 / 60)),
                                        v_date_begin + ((30 * k) / 24 / 60));
                            end loop;
                    end loop;
            end loop;
    end;
    commit;

    select id bulk collect
    into a_tickets
    from KOTLYAROV_DM.tickets;

    -- users
    DBMS_OUTPUT.PUT_LINE('users');
    for i in 1..5
        loop
            insert into KOTLYAROV_DM.users (name, email, password)
            values ('user ' || i,
                    dbms_random.string('A', 5) || '@' || dbms_random.string('A', 10),
                    dbms_random.string('A', 10));
        end loop;
    commit;

    select id bulk collect
    into a_users
    from KOTLYAROV_DM.users;

    -- patients
    DBMS_OUTPUT.PUT_LINE('patients');
    for i in a_users.first..a_users.last
        loop
            for j in 1..5
                loop
                    insert into KOTLYAROV_DM.patients (id_user, first_name, last_name, patronymic, birthdate, id_gender,
                                                       phone,
                                                       area)
                    values (a_users(i),
                            dbms_random.string('A', 10),
                            dbms_random.string('A', 10),
                            dbms_random.string('A', 10),
                            to_date(floor(dbms_random.VALUE(1940, 2021)) || '.06.01', 'yyyy.mm.dd'),
                            floor(dbms_random.VALUE(1, 4)),
                            floor(dbms_random.VALUE(70000000000, 79999999999)),
                            'area ' || floor(dbms_random.VALUE(1, v_hospitals_count)));

                end loop;
        end loop;
    commit;

    select id bulk collect
    into a_patients
    from KOTLYAROV_DM.patients;

    -- patient_documents
    DBMS_OUTPUT.PUT_LINE('patient_documents');
    for i in a_patients.first..a_patients.last
        loop
            insert into KOTLYAROV_DM.patient_documents (name, id_patient, content, file_name, id_document_type)
            values (dbms_random.string('A', 10),
                    a_patients(i),
                    null,
                    dbms_random.string('A', 5),
                    floor(dbms_random.VALUE(1, 3)));
        end loop;
    commit;

    -- patient_journals
    DBMS_OUTPUT.PUT_LINE('patient_journals');
    declare
        v_id_first_patient number := a_patients.FIRST;
        v_id_last_patient  number := a_patients.LAST;
    begin
        select id bulk collect
        into a_tickets
        from KOTLYAROV_DM.tickets
        where CLOSED = 1;

        for i in a_tickets.first..a_tickets.last
            loop
                insert into KOTLYAROV_DM.patient_journals (id_patient, id_ticket, status)
                values (a_patients(floor(dbms_random.VALUE(v_id_first_patient, v_id_last_patient))),
                        a_tickets(i),
                        0);
            end loop;
    end;
end;
commit;