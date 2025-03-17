CREATE OR REPLACE TRIGGER trg_servicios
BEFORE INSERT OR UPDATE ON SERVICIOS
FOR EACH ROW
DECLARE
    v_cliente_exists NUMBER;
    v_sucursal_exists NUMBER;
    v_ciudad CLIENTES.CIUDAD_CL%TYPE;
    v_segmento CLIENTES.SEGMENTO_CL%TYPE;
BEGIN
    SELECT COUNT(*) INTO v_cliente_exists FROM CLIENTES WHERE id_cliente = :NEW.fk_clientes;
    IF v_cliente_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20000, 'El cliente no existe');
    END IF;

    SELECT COUNT(*) INTO v_sucursal_exists FROM SUCURSALES WHERE id_sucursal = :NEW.fk_sucursales;
    IF v_sucursal_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'La sucursal no existe');
    END IF;

    SELECT ciudad_cl, segmento_cl INTO v_ciudad, v_segmento FROM CLIENTES WHERE id_cliente = :NEW.fk_clientes;
    IF v_ciudad != 'BOGOT�' OR v_segmento != 'MUJER' THEN
            RAISE_APPLICATION_ERROR(-20002, 'El cliente debe ser de Bogotá y del segmento Mujer.');
    END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'No se pudo recuperar la informacion del cliente.');
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
    VALUES ('VENDEDORES', v_evento, SYSTIMESTAMP);
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
    VALUES ('CANALES', v_evento, SYSTIMESTAMP);
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
    VALUES ('SUCURSALES', v_evento, SYSTIMESTAMP);
END;
/