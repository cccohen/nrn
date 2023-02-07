#pragma once
#include "neuron/container/mechanism.hpp"
#include "neuron/container/soa_container.hpp"

namespace neuron::container::Mechanism {
/** @brief Underlying storage for all instances of a particular Mechanism.
 */
struct storage: soa<storage, field::FloatingPoint> {
    using base_type = soa<storage, field::FloatingPoint>;
    // Defined in .cpp to avoid instantiating base_type constructors too often.
    storage(short mech_type, std::string name, std::vector<Variable> floating_point_fields = {});
    [[nodiscard]] int num_floating_point_fields() const;
    [[nodiscard]] auto name() const {
        return m_mech_name;
    }
    [[nodiscard]] constexpr short type() const {
        return m_mech_type;
    }
    friend std::ostream& operator<<(std::ostream& os, storage const& data) {
        return os << data.name() << "::storage{type=" << data.type() << ", "
                  << data.num_floating_point_fields() << " fields}";
    }

  private:
    short m_mech_type{};
    std::string m_mech_name{};
};

/**
 * @brief Non-owning handle to a Mechanism instance.
 */
using handle = handle_interface<non_owning_identifier<storage>>;

/**
 * @brief Owning handle to a Mechanism instance.
 */
using owning_handle = handle_interface<owning_identifier<storage>>;
}  // namespace neuron::container::Mechanism
