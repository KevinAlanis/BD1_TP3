package com.registro.usuarios.controlador;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import com.registro.usuarios.modelo.Empleado;
import com.registro.usuarios.repositorio.EmpleadoRepository;
import com.registro.usuarios.repositorio.PuestoRepository;
import org.springframework.web.bind.annotation.PathVariable;
@Controller
public class EmpleadoController {
    @Autowired
    private EmpleadoRepository empleadoRepository;
    @Autowired
    private PuestoRepository puestoRepository;
    @GetMapping("/empleados")
    public String getEmpleados(Model model) {
        model.addAttribute("empleados", empleadoRepository.findAll());
        return "empleados";
    }
    @GetMapping("/empleados/nuevo")
    public String nuevoEmpleadoForm(Model model) {
        Empleado empleado = new Empleado();
        model.addAttribute("empleado", empleado);
        model.addAttribute("puestos", puestoRepository.findAll()); 
        return "agregarEmpleado";
    }
    @PostMapping("/empleados/guardar")
    public String guardarEmpleado(Empleado empleado) {
        empleadoRepository.save(empleado);
        return "redirect:/empleados";
    }
    @PostMapping("/empleados/eliminar/{id}")
    public String eliminarEmpleado(@PathVariable("id") Long id) {
        empleadoRepository.deleteById(id);
        return "redirect:/empleados";  
    }
    @GetMapping("/empleados/editar/{id}")
    public String editarEmpleadoForm(@PathVariable("id") Long id, Model model) {
        Empleado empleado = empleadoRepository.findById(id).orElseThrow(() -> new IllegalArgumentException("Empleado no encontrado"));
        model.addAttribute("empleado", empleado);
        model.addAttribute("puestos", puestoRepository.findAll()); 
        return "editarEmpleado";
    }
    @PostMapping("/empleados/actualizar")
    public String actualizarEmpleado(Empleado empleado) {
        empleadoRepository.save(empleado);
        return "redirect:/empleados";
    }
}
