SET SERVEROUTPUT ON;

-- Requerimiento 1
DECLARE
CURSOR cursor_cli
  IS
  SELECT ID_CLIENTE, TRIM(NOMBRE_CL) AS NOMBRE_CL FROM CLIENTES ORDER BY NOMBRE_CL;

CURSOR cursor_fac(id_cliente FACTURAS.FK_CLIENTES%TYPE)
  IS 
  SELECT * FROM FACTURAS WHERE id_cliente = fk_clientes ORDER BY TO_NUMBER(ID_FACTURA);

CURSOR cursor_cob(id_fact COBRANZAS.FK_FACTURAS%TYPE) 
  IS 
  SELECT * FROM COBRANZAS WHERE fk_facturas = id_fact ORDER BY TO_NUMBER(ID_COBRANZA);

v_canal_venta CANALES.CANAL_VENTA%TYPE default NULL;
v_cobrado COBRANZAS.VALOR_COBRADO%TYPE default 0;
v_pendiente COBRANZAS.VALOR_COBRADO%TYPE default 0;
BEGIN
  FOR reg_cli IN cursor_cli LOOP
    FOR reg_fac IN cursor_fac(reg_cli.id_cliente) LOOP
      SELECT canal_venta INTO v_canal_venta FROM CANALES WHERE id_canal = reg_fac.fk_canales;
      -- DBMS_OUTPUT.PUT_LINE(CHR(10)|| 'ID Factura: ' || reg_fac.id_factura || ', Fecha: '|| reg_fac.fecha_factura ||
      --                       ', Canal de Venta: ' || v_canal_venta);
      
      v_cobrado := 0;
      FOR reg_cob IN cursor_cob(reg_fac.id_factura) LOOP
        v_cobrado := v_cobrado + reg_cob.valor_cobrado;
        -- DBMS_OUTPUT.PUT_LINE('    ID Cobranza: ' || reg_cob.id_cobranza || ', Fecha: ' || reg_cob.fecha_cobro ||
        --                       ', Valor: ' || reg_cob.valor_cobrado);
      END LOOP;

      IF v_cobrado = reg_fac.total_factura THEN
        DBMS_OUTPUT.PUT_LINE('La factura ' || reg_fac.id_factura || ' del cliente ' || reg_cli.nombre_cl || 
                              ' de monto ' || reg_fac.total_factura || ' fue cobrada en su totalidad');
      ELSE
        v_pendiente := reg_fac.total_factura - v_cobrado;
        DBMS_OUTPUT.PUT_LINE('La factura ' || reg_fac.id_factura || ' del cliente ' || reg_cli.nombre_cl || 
                              ' de monto ' || reg_fac.total_factura || ' fue cobrada parcialmente por un monto de ' || 
                              v_cobrado || ' y tiene una deuda pendiente de ' || v_pendiente);
      END IF;
    END LOOP;
  END LOOP;

EXCEPTION
  WHEN VALUE_ERROR THEN
    DBMS_OUTPUT.PUT_LINE('Error: Se intentó realizar una conversión inválida.');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);

END;
/
