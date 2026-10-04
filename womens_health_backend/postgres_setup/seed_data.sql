--
-- PostgreSQL database dump
--

\restrict nfiSzBM1yT8zhAAoidR7z6Yj54CnUfztGBfS7Y0SGqQ14Vcdc3aePf6j8IOTwX4

-- Dumped from database version 18.6 (Postgres.app)
-- Dumped by pg_dump version 18.6 (Postgres.app)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.roles VALUES (1, 'patient');
INSERT INTO public.roles VALUES (2, 'nurse');
INSERT INTO public.roles VALUES (3, 'doctor');
INSERT INTO public.roles VALUES (4, 'admin');


--
-- Data for Name: services; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.services VALUES (1, 'General Consultation', 'General womens health check-up', true);
INSERT INTO public.services VALUES (2, 'Prenatal Care', 'Pregnancy monitoring and check-ups', true);
INSERT INTO public.services VALUES (3, 'Family Planning', 'Contraception and reproductive health guidance', true);


--
-- Name: services_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.services_id_seq', 3, true);


--
-- PostgreSQL database dump complete
--

\unrestrict nfiSzBM1yT8zhAAoidR7z6Yj54CnUfztGBfS7Y0SGqQ14Vcdc3aePf6j8IOTwX4

