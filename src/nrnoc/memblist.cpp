#include "neuron/container/generic_data_handle.hpp"
#include "neuron/container/mechanism_data.hpp"
#include "nrnoc_ml.h"

#include <cassert>
#include <iterator>  // std::distance, std::next

Memb_list::Memb_list(int type)
    : m_storage{&neuron::model().mechanism_data(type)} {
    assert(type == m_storage->type());
}

[[nodiscard]] std::vector<double*> Memb_list::data() {
    assert(m_storage);
    assert(m_storage_offset != std::numeric_limits<std::size_t>::max());
    auto const num_fields = m_storage->num_floating_point_fields();
    std::vector<double*> ret(num_fields, nullptr);
    for (auto i = 0; i < num_fields; ++i) {
        ret[i] = &m_storage->get_field_instance<neuron::container::Mechanism::field::FloatingPoint>(
            m_storage_offset, i);
    }
    return ret;
}

[[nodiscard]] double& Memb_list::data(std::size_t instance, int variable, int array_index) {
    assert(m_storage);
    assert(m_storage_offset != std::numeric_limits<std::size_t>::max());
    return m_storage->get_field_instance<neuron::container::Mechanism::field::FloatingPoint>(
        m_storage_offset + instance, variable, array_index);
}

[[nodiscard]] double const& Memb_list::data(std::size_t instance,
                                            int variable,
                                            int array_index) const {
    assert(m_storage);
    assert(m_storage_offset != std::numeric_limits<std::size_t>::max());
    return m_storage->get_field_instance<neuron::container::Mechanism::field::FloatingPoint>(
        m_storage_offset + instance, variable, array_index);
}


[[nodiscard]] std::ptrdiff_t Memb_list::legacy_index(double const* ptr) const {
    assert(m_storage_offset != std::numeric_limits<std::size_t>::max());
    auto const size = m_storage->size();
    auto const num_fields = m_storage->num_floating_point_fields();
    for (auto field = 0; field < num_fields; ++field) {
        auto const* const vec_data =
            &m_storage->get_field_instance<neuron::container::Mechanism::field::FloatingPoint>(
                0, field);
        auto const index = std::distance(vec_data, ptr);
        if (index >= 0 && index < size) {
            // ptr lives in the field-th data column
            return (index - m_storage_offset) * num_fields + field;
        }
    }
    // ptr doesn't live in this mechanism data, cannot compute a legacy index
    return -1;
}

[[nodiscard]] std::size_t Memb_list::num_floating_point_fields() const {
    assert(m_storage);
    return m_storage->num_floating_point_fields();
}

[[nodiscard]] double* Memb_list::dptr_field(std::size_t instance, int variable) {
    return pdata[instance][variable].get<double*>();
}

[[nodiscard]] int Memb_list::type() const {
    assert(m_storage);
    return m_storage->type();
}
