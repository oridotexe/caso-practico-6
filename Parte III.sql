CREATE OR REPLACE TRIGGER trg_servicios
BEFORE INSERT OR UPDATE ON SERVICIOS
FOR EACH ROW
DECLARE
    v_cliente_exists NUMBER;
    v_sucursal_exists NUMBER;
    v_ciudad VARCHAR2(100);
    v_segmento VARCHAR2(100);
BEGIN
    SELECT COUNT(*) INTO v_cliente_exists FROM CLIENTES WHERE id_cliente = :NEW.fk_clientes;
    IF v_cliente_exists = 0 THEN
        DBMS_OUTPUT.PUT_LINE('El cliente no existe');
    END IF;

    SELECT COUNT(*) INTO v_sucursal_exists FROM SUCURSALES WHERE id_sucursal = :NEW.fk_sucursales;
    IF v_sucursal_exists = 0 THEN
        DBMS_OUTPUT.PUT_LINE('La sucursal no existe');
    END IF;

    SELECT ciudad_cl, segmento_cl INTO v_ciudad, v_segmento FROM CLIENTES WHERE id_cliente = :NEW.fk_clientes;
    IF v_ciudad != 'Bogotá' OR v_segmento != 'Mujer' THEN
        DBMS_OUTPUT.PUT_LINE('El cliente debe ser de Bogotá y del segmento Mujer');
    END IF;
END;
/

-- tabla bitacora
DROP TABLE BITACORA CASCADE CONSTRAINTS;

CREATE TABLE BITACORA(
    NOMBRE_TABLA VARCHAR2(50) NOT NULL,
    EVENTO       VARCHAR2(50) NOT NULL,
    FECHA_Y_HORA   TIMESTAMP NOT NULL   
);


CREATE OR REPLACE TRIGGER trg_bitacora_vendedores
AFTER INSERT OR UPDATE OR DELETE ON vendedores
FOR EACH ROW
DECLARE
    v_evento VARCHAR2(50);
BEGIN
    IF INSERTING THEN v_evento := 'INSERT';
    ELSIF UPDATING THEN v_evento := 'UPDATE';
    ELSIF DELETING THEN v_evento := 'DELETE';
    END IF;
    
    INSERT INTO bitacora (nombre_tabla, evento, fecha_y_hora)
    VALUES ('Vendedores', v_evento, SYSTIMESTAMP);
END;
/

CREATE OR REPLACE TRIGGER trg_bitacora_canales
AFTER INSERT OR UPDATE OR DELETE ON canales
FOR EACH ROW
DECLARE
    v_evento VARCHAR2(50);
BEGIN
    IF INSERTING THEN v_evento := 'INSERT';
    ELSIF UPDATING THEN v_evento := 'UPDATE';
    ELSIF DELETING THEN v_evento := 'DELETE';
    END IF;
    
    INSERT INTO bitacora (nombre_tabla, evento, fecha_y_hora)
    VALUES ('Canales', v_evento, SYSTIMESTAMP);
END;
/

CREATE OR REPLACE TRIGGER trg_bitacora_sucursales
AFTER INSERT OR UPDATE OR DELETE ON sucursales
FOR EACH ROW
DECLARE
    v_evento VARCHAR2(50);
BEGIN
    IF INSERTING THEN v_evento := 'INSERT';
    ELSIF UPDATING THEN v_evento := 'UPDATE';
    ELSIF DELETING THEN v_evento := 'DELETE';
    END IF;
    
    INSERT INTO bitacora (nombre_tabla, evento, fecha_y_hora)
    VALUES ('Sucursales', v_evento, SYSTIMESTAMP);
END;
/


