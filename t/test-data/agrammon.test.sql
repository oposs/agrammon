INSERT INTO role (role_id, role_name)
VALUES (0, 'admin'), (1,'user'), (2,'support');

INSERT INTO pers (pers_email, pers_password, pers_role)
VALUES ('test@agrammon.ch', 'should_be_encrypted_password', 0);
