
DROP TABLE RESUMEN_COMISIONES_VENDEDORES CASCADE CONSTRAINTS

CREATE TABLE RESUMEN_COMISIONES_VENDEDORES (
    AÑO                 NUMBER(4) NOT NULL,
    MES                 NUMBER(2) NOT NULL,
    VENDEDOR            VARCHAR2(300 CHAR) NOT NULL,
    CANT_FACTURAS       NUMBER NOT NULL,
    MONTO_TOTAL_FACT    NUMBER(10, 2) NOT NULL,
    MONTO_TOTAL_COBRADO NUMBER(10, 2) NOT NULL,
    MONTO_TOTAL_POR_COBRAR NUMBER(10, 2) NOT NULL,
    PORCENTAJE_COMISION NUMBER(5, 2) NOT NULL,
    MONTO_COMISION      NUMBER(10, 2) NOT NULL
);

-- FUNCIONES:

CREATE OR REPLACE FUNCTION CALCULAR_COMISION(P_MONTO_COBRADO NUMBER) RETURN NUMBER IS
    CONSTANTE_COMISION NUMBER := 15;
BEGIN
    RETURN P_MONTO_COBRADO * (CONSTANTE_COMISION / 100);
END;


----

CREATE OR REPLACE FUNCTION VALIDAR_AÑO_TRANSACCIONES(P_AÑO NUMBER) RETURN BOOLEAN IS
    V_COUNT NUMBER;
BEGIN
    SELECT COUNT(*) INTO V_COUNT 
    FROM FACTURAS 
    WHERE EXTRACT(YEAR FROM FECHA_FACTURA) = P_AÑO;

    RETURN V_COUNT > 0;
END;

---

CREATE OR REPLACE FUNCTION VALIDAR_MES_SIGUIENTE(P_AÑO NUMBER, P_MES NUMBER) RETURN BOOLEAN IS
    V_ULTIMO_AÑO NUMBER;
    V_ULTIMO_MES NUMBER;
BEGIN
    
    SELECT NVL(MAX(AÑO), 0)
    INTO V_ULTIMO_AÑO
    FROM RESUMEN_COMISIONES_VENDEDORES;
    
    IF V_ULTIMO_AÑO = 0 THEN
        RETURN TRUE;
    END IF;
    
    SELECT NVL(MAX(MES), 0)
    INTO V_ULTIMO_MES
    FROM RESUMEN_COMISIONES_VENDEDORES
    WHERE AÑO = V_ULTIMO_AÑO;

    IF (P_AÑO = V_ULTIMO_AÑO AND P_MES = V_ULTIMO_MES + 1) OR 
       (P_AÑO = V_ULTIMO_AÑO + 1 AND P_MES = 1 AND V_ULTIMO_MES = 12) THEN
        RETURN TRUE;
    END IF;

    RETURN FALSE;
END;

-- PROCEDIMIENTO

CREATE OR REPLACE PROCEDURE CARGAR_COMISIONES_VENDEDORES(P_AÑO NUMBER, P_MES NUMBER) IS
    CURSOR CUR_VENDEDORES IS
        SELECT ID_VENDEDOR, VENDEDOR FROM VENDEDORES;

    V_CANT_FACTURAS NUMBER;
    V_MONTO_TOTAL_FACT NUMBER(10,2);
    V_MONTO_TOTAL_COBRADO NUMBER(10,2);
    V_MONTO_TOTAL_POR_COBRAR NUMBER(10,2);
    V_MONTO_COMISION NUMBER(10,2);

BEGIN

    IF NOT VALIDAR_AÑO_TRANSACCIONES(P_AÑO) THEN
        RAISE_APPLICATION_ERROR(-20001, 'NO EXISTEN TRANSACCIONES PARA EL AÑO ESPECIFICADO.');
    END IF;

    IF NOT VALIDAR_MES_SIGUIENTE(P_AÑO, P_MES) THEN
        RAISE_APPLICATION_ERROR(-20002, 'EL MES DEBE SER EL SIGUIENTE AL ÚLTIMO PROCESADO.');
    END IF;

  
    FOR REC IN CUR_VENDEDORES LOOP
     
        SELECT COUNT(*), NVL(SUM(F.TOTAL_FACTURA), 0) 
        INTO V_CANT_FACTURAS, V_MONTO_TOTAL_FACT
        FROM FACTURAS F
        WHERE F.FK_VENDEDORES = REC.ID_VENDEDOR
        AND EXTRACT(YEAR FROM F.FECHA_FACTURA) = P_AÑO
        AND EXTRACT(MONTH FROM F.FECHA_FACTURA) = P_MES;
             
        IF V_CANT_FACTURAS = 0 THEN
            CONTINUE;
        END IF;

        SELECT NVL(SUM(C.VALOR_COBRADO), 0) 
        INTO V_MONTO_TOTAL_COBRADO
        FROM COBRANZAS C
        JOIN FACTURAS F ON C.FK_FACTURAS = F.ID_FACTURA
        WHERE F.FK_VENDEDORES = REC.ID_VENDEDOR
        AND EXTRACT(YEAR FROM F.FECHA_FACTURA) = P_AÑO
        AND EXTRACT(MONTH FROM C.FECHA_COBRO) = P_MES;

        V_MONTO_TOTAL_POR_COBRAR := V_MONTO_TOTAL_FACT - V_MONTO_TOTAL_COBRADO;

        V_MONTO_COMISION := CALCULAR_COMISION(V_MONTO_TOTAL_COBRADO);

        INSERT INTO RESUMEN_COMISIONES_VENDEDORES (
            AÑO, MES, VENDEDOR, CANT_FACTURAS, MONTO_TOTAL_FACT, MONTO_TOTAL_COBRADO, 
            MONTO_TOTAL_POR_COBRAR, PORCENTAJE_COMISION, MONTO_COMISION
        ) VALUES (
            P_AÑO, P_MES, REC.VENDEDOR, V_CANT_FACTURAS, V_MONTO_TOTAL_FACT, V_MONTO_TOTAL_COBRADO,
            V_MONTO_TOTAL_POR_COBRAR, 15, V_MONTO_COMISION
        );
    END LOOP;

    COMMIT;
END;
